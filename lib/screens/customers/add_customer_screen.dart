import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/debity_button.dart';
import '../../core/widgets/debity_input.dart';
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
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: Text(
          _isEditing ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addCustomerButton,
          style: AppTextStyles.sectionTitle,
        ),
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageH,
            vertical: AppSpacing.sp24,
          ),
          children: [
            // Avatar Preview
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.brand500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand500, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : '؟',
                  style: AppTextStyles.xl4.copyWith(
                    color: AppColors.brand400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp32),

            // Basic Info Card
                SectionPanel(
              title: AppLocalizations.of(context).basicInfo,
              child: Column(
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
                  const SizedBox(height: AppSpacing.sp16),
                  DebityTextField(
                    controller: _phoneController,
                    label: AppLocalizations.of(context).phone_label + ' *',
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sp24),

            // Extra Info Card
            SectionPanel(
              title: AppLocalizations.of(context).extraInfo,
              child: Column(
                children: [
                  DebityTextField(
                    controller: _addressController,
                    label: AppLocalizations.of(context).addressLabel,
                    hintText: AppLocalizations.of(context).addressHint,
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sp16),
                  DebityTextField(
                    controller: _notesController,
                    label: AppLocalizations.of(context).notesLabel,
                    hintText: AppLocalizations.of(context).notesLabel,
                    prefixIcon: const Icon(Icons.note_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sp32),

            // Save Button
            DebityPrimaryButton(
              label: _isEditing ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addCustomerButton,
              isLoading: _isLoading,
              onPressed: _saveCustomer,
            ),
          ],
        ),
      ),
    );
  }
}
