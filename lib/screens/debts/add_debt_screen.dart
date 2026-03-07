import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart'; 
import '../../core/widgets/debity_button.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer.dart';
import 'package:intl/intl.dart';
import '../../models/debt.dart';

class AddDebtScreen extends StatefulWidget {
  final Customer? customer;

  const AddDebtScreen({super.key, this.customer});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _itemNameController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _downPaymentController = TextEditingController(text: '0');
  final _installmentsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingCustomers = true;
  
  // NEW: Purely for UI tracking in the Stepper
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[AddDebtScreen] initState — pre-selected customer: ${widget.customer?.name ?? "none"}',
    );
    _selectedCustomer = widget.customer;
    _loadCustomers();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _downPaymentController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS REMAIN EXACTLY THE SAME ---

  Future<void> _loadCustomers() async {
    debugPrint('[AddDebtScreen] _loadCustomers → fetching customers from Supabase...');
    try {
      final response = await _supabase
          .from('customers')
          .select('id, name, phone, address, notes, created_at, updated_at')
          .order('name');

      if (mounted) {
        setState(() {
          _customers = (response as List).map((data) => Customer.fromJson(data)).toList();
          if (widget.customer != null) {
            final matches = _customers.where((c) => c.id == widget.customer!.id);
            if (matches.isNotEmpty) {
              _selectedCustomer = matches.first;
            } else if (_customers.isNotEmpty) {
              _selectedCustomer = _customers.first;
            }
          }
          _isLoadingCustomers = false;
        });
      }
    } catch (e, st) {
      debugPrint('[AddDebtScreen] _loadCustomers ERROR: $e');
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل العملاء: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(data: AppTheme.darkTheme, child: child!);
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final downPaymentText = _downPaymentController.text.trim().replaceAll(',', '');
      final downPaymentVal = downPaymentText.isEmpty ? 0.0 : double.parse(downPaymentText);
      final double sellingPrice = double.parse(_sellingPriceController.text.replaceAll(',', ''));
      final double originalPrice = double.parse(_originalPriceController.text.replaceAll(',', ''));
      final int numInstallments = int.parse(_installmentsController.text);

      final double totalAmount = sellingPrice - downPaymentVal;
      final double installmentAmount = numInstallments > 0 ? (totalAmount / numInstallments) : totalAmount;

      final debtObj = Debt(
        customerId: _selectedCustomer!.id!,
        itemName: _itemNameController.text.trim(),
        itemDescription: _itemDescController.text.trim().isEmpty ? null : _itemDescController.text.trim(),
        originalPrice: originalPrice,
        sellingPrice: sellingPrice,
        downPayment: downPaymentVal,
        totalAmount: totalAmount,
        remainingAmount: totalAmount,
        numberOfInstallments: numInstallments,
        installmentAmount: installmentAmount,
        startDate: _startDate,
        status: DebtStatus.active,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final debtResponse = await _supabase.from('debts').insert(debtObj.toJson()).select().single();
      final debtId = debtResponse['id'];

      List<Map<String, dynamic>> installments = [];
      for (int i = 0; i < numInstallments; i++) {
        final dueDate = DateTime(_startDate.year, _startDate.month + i, _startDate.day);
        installments.add({
          'debt_id': debtId,
          'amount': installmentAmount,
          'due_date': dueDate.toIso8601String(),
          'status': 'pending',
          'installment_number': i + 1,
        });
      }

      await _supabase.from('installments').insert(installments);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الدين بنجاح')));
      }
    } catch (e, st) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // --- NEW UI LAYOUT ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: Text('إضافة دين جديد', style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.surface0,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingCustomers
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : Form(
              key: _formKey,
              child: Theme(
                // Adjusting Stepper theme to match your app colors
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
                    final isLastStep = _currentStep == _getSteps().length - 1;
                    if (isLastStep) {
                      _saveDebt();
                    } else {
                      setState(() => _currentStep += 1);
                    }
                  },
                  onStepCancel: _currentStep == 0
                      ? null
                      : () => setState(() => _currentStep -= 1),
                  
                  // Customizing the Stepper buttons to use your DebityPrimaryButton
                  controlsBuilder: (context, details) {
                    final isLastStep = _currentStep == _getSteps().length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sp24),
                      child: Row(
                        children: [
                          Expanded(
                            child: DebityPrimaryButton(
                              label: isLastStep ? 'حفظ الدين' : 'التالي',
                              isLoading: _isLoading && isLastStep,
                              onPressed: details.onStepContinue,
                            ),
                          ),
                          if (_currentStep != 0) ...[
                            const SizedBox(width: AppSpacing.sp16),
                            Expanded(
                              child: TextButton(
                                onPressed: details.onStepCancel,
                                child: Text(
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
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
        title: const Text('بيانات العميل'),
        content: _buildCustomerInput(),
      ),
      Step(
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        title: const Text('معلومات المنتج'),
        content: _buildItemInfoInput(),
      ),
      Step(
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        title: const Text('التسعير'),
        content: _buildPricingInput(),
      ),
      Step(
        isActive: _currentStep >= 3,
        title: const Text('الأقساط والملاحظات'),
        content: Column(
          children: [
            _buildInstallmentsInput(),
            const SizedBox(height: AppSpacing.sp24),
            _buildNotesInput(),
          ],
        ),
      ),
    ];
  }

  // I removed the 'SectionPanel' wrappers here because the Stepper's 'Step' acts as the visual container.

  Widget _buildCustomerInput() {
    return DropdownMenu<Customer>(
      initialSelection: _selectedCustomer,
      expandedInsets: EdgeInsets.zero,
      enableSearch: true,
      enableFilter: true,
      requestFocusOnTap: true,
      label: const Text('اختر العميل *'),
      textStyle: AppTextStyles.base.copyWith(color: AppColors.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand500, width: 2),
        ),
      ),
      leadingIcon: const Icon(
        Icons.person_search_rounded,
        color: AppColors.textMuted,
      ),
      dropdownMenuEntries: _customers.map((c) {
        return DropdownMenuEntry<Customer>(
          value: c,
          label: c.name,
          style: MenuItemButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }).toList(),
      onSelected: (v) => setState(() => _selectedCustomer = v),
    );
  }

  Widget _buildItemInfoInput() {
    return Column(
      children: [
        DebityTextField(
          controller: _itemNameController,
          label: 'اسم المنتج *',
          prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء إدخال اسم المنتج' : null,
        ),
        const SizedBox(height: AppSpacing.sp16),
        DebityTextField(
          controller: _itemDescController,
          label: 'وصف المنتج',
          prefixIcon: const Icon(Icons.description_outlined, color: AppColors.textMuted),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPricingInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DebityTextField(
            controller: _originalPriceController,
            label: 'السعر الأصلي *',
            prefixIcon: const Icon(Icons.sell_outlined, color: AppColors.textMuted),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (double.tryParse(v.replaceAll(',', '')) == null) return 'غير صحيح';
              return null;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sp16),
        Expanded(
          child: DebityTextField(
            controller: _sellingPriceController,
            label: 'سعر البيع *',
            prefixIcon: const Icon(Icons.point_of_sale_rounded, color: AppColors.textMuted),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (double.tryParse(v.replaceAll(',', '')) == null) return 'غير صحيح';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentsInput() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DebityTextField(
                controller: _downPaymentController,
                label: 'المقدمة',
                prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textMuted),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.sp16),
            Expanded(
              child: DebityTextField(
                controller: _installmentsController,
                label: 'الأقساط *',
                prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: AppColors.textMuted),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return 'غير صحيح';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp16),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: DebityTextField(
              controller: TextEditingController(
                text: DateFormat('yyyy/MM/dd').format(_startDate),
              ),
              label: 'تاريخ بداية الأقساط',
              prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.brand500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return DebityTextField(
      controller: _notesController,
      label: 'ملاحظات إضافية',
      prefixIcon: const Icon(Icons.sticky_note_2_outlined, color: AppColors.textMuted),
      maxLines: 3,
    );
  }
}