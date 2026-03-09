import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/debity_button.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/customer.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _addressController = TextEditingController(text: widget.customer?.address);
    _notesController = TextEditingController(text: widget.customer?.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customerData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (_isEditing) {
        customerData['updated_at'] = DateTime.now().toIso8601String();
        final updatedCustomer = await ApiService().updateCustomer(
          widget.customer!.id!,
          customerData,
        );

        if (mounted) {
          Navigator.pop(context, updatedCustomer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).updateCustomerSuccess)),
          );
        }
      } else {
        customerData['created_at'] = DateTime.now().toIso8601String();
        await ApiService().createCustomer(customerData);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).addCustomerSuccess)),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).deleteError}: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surface0,
      appBar: AppBar(
        title: Text(
          _isEditing ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addCustomerButton,
          style: AppTextStyles.sectionTitle,
        ),
        backgroundColor: AppColors.of(context).surface0,
        foregroundColor: AppColors.of(context).textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.brand500,
              ),
            ),
            child: Stepper(
              type: StepperType.vertical,
              physics: const BouncingScrollPhysics(),
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                // Optional Enhancement: Validate the current step before allowing 'Next'
                if (_currentStep == 0 && _nameController.text.trim().length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).nameTooShort), backgroundColor: AppColors.danger),
                  );
                  return;
                }
                if (_currentStep == 1 && _phoneController.text.trim().length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('رقم الهاتف غير صحيح'), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                final isLastStep = _currentStep == _getSteps().length - 1;
                if (isLastStep) {
                  _saveCustomer();
                } else {
                  setState(() => _currentStep += 1);
                }
              },
              onStepCancel: _currentStep == 0
                  ? null
                  : () => setState(() => _currentStep -= 1),
              
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == _getSteps().length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sp24),
                  child: Row(
                    children: [
                      Expanded(
                        child: DebityPrimaryButton(
                          label: isLastStep 
                            ? (_isEditing ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addCustomerButton) 
                            : 'التالي',
                          isLoading: _isLoading && isLastStep,
                          onPressed: details.onStepContinue,
                        ),
                      ),
                      if (_currentStep != 0) ...[
                        const SizedBox(width: AppSpacing.sp16),
                        Expanded(
                          child: TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text(
                              'رجوع',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
              steps: _getSteps(),
            ),
          ),
        ),
      ),
    );
  }

  // Broken down into 4 clear steps
  List<Step> _getSteps() {
    return [
      Step(
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
        title: Text(AppLocalizations.of(context).nameLabel), // "الاسم"
        content: _buildIdentityInput(),
      ),
      Step(
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        title: Text(AppLocalizations.of(context).phone_label), // "رقم الهاتف"
        content: _buildContactInput(),
      ),
      Step(
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        title: Text(AppLocalizations.of(context).addressLabel), // "العنوان"
        content: _buildAddressInput(),
      ),
      Step(
        isActive: _currentStep >= 3,
        title: Text(AppLocalizations.of(context).notesLabel), // "ملاحظات"
        content: _buildNotesInput(),
      ),
    ];
  }

  Widget _buildIdentityInput() {
    return Column(
      children: [
        DebityTextField(
          controller: _nameController,
          label: '${AppLocalizations.of(context).nameLabel} *',
          hintText: AppLocalizations.of(context).nameLabel,
          prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.textMuted),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).nameRequired;
            }
            if (value.trim().length < 2) {
              return AppLocalizations.of(context).nameTooShort;
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildContactInput() {
    return DebityTextField(
      controller: _phoneController,
      label: '${AppLocalizations.of(context).phone_label} *',
      hintText: '07xxxxxxxxx',
      prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.textMuted),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).phone_required;
        }
        if (value.trim().length < 10) return 'رقم الهاتف غير صحيح';
        return null;
      },
    );
  }

  Widget _buildAddressInput() {
    return DebityTextField(
      controller: _addressController,
      label: AppLocalizations.of(context).addressLabel,
      hintText: AppLocalizations.of(context).addressHint,
      prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.textMuted),
    );
  }

  Widget _buildNotesInput() {
    return DebityTextField(
      controller: _notesController,
      label: AppLocalizations.of(context).notesLabel,
      hintText: AppLocalizations.of(context).notesLabel,
      prefixIcon: const Icon(Icons.note_rounded, color: AppColors.textMuted),
      maxLines: 3, // Increased lines slightly since it has its own dedicated step now
    );
  }
}