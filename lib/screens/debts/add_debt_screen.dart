import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/debity_button.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer.dart';
import 'package:intl/intl.dart';
import '../../models/debt.dart';
import '../customers/add_customer_screen.dart';

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

  Customer? _selectedCustomer;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  // Typeahead state
  final _customerSearchController = TextEditingController();
  final _customerFocusNode = FocusNode();
  List<Customer> _suggestions = [];
  bool _isSearchingCustomer = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  final Map<String, List<Customer>> _queryCache = {};
  final List<Customer> _recentCustomers = [];
  
  // NEW: Purely for UI tracking in the Stepper
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[AddDebtScreen] initState — pre-selected customer: ${widget.customer?.name ?? "none"}',
    );
    _selectedCustomer = widget.customer;
    if (widget.customer != null) {
      _customerSearchController.text = widget.customer!.name;
    }
    _customerFocusNode.addListener(() {
      if (!_customerFocusNode.hasFocus && mounted) {
        // Small delay so tapping a suggestion registers before hiding the list
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
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
    _customerSearchController.dispose();
    _customerFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  void _onCustomerSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = List.from(_recentCustomers);
        _isSearchingCustomer = false;
      });
      return;
    }
    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      () => _searchCustomers(query),
    );
  }

  Future<void> _searchCustomers(String query) async {
    final cacheKey = query.toLowerCase().trim();
    if (_queryCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _suggestions = _queryCache[cacheKey]!;
          _isSearchingCustomer = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _isSearchingCustomer = true);
    try {
      final resp = await _supabase
          .from('customers')
          .select('id, name, phone, address, notes, created_at, updated_at')
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .limit(20)
          .order('name');
      final results = (resp as List).map((e) => Customer.fromJson(e)).toList();
      _queryCache[cacheKey] = results;
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearchingCustomer = false;
        });
      }
    } catch (e) {
      debugPrint('[AddDebtScreen] _searchCustomers ERROR: $e');
      if (mounted) setState(() => _isSearchingCustomer = false);
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
    } catch (e) {
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
      backgroundColor: AppColors.of(context).surface0,
      appBar: AppBar(
        title: Text('إضافة دين جديد', style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.of(context).surface0,
        foregroundColor: AppColors.of(context).textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _customerSearchController,
          focusNode: _customerFocusNode,
          style: AppTextStyles.base.copyWith(color: AppColors.of(context).textPrimary),
          decoration: InputDecoration(
            labelText: 'اختر العميل *',
            labelStyle: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.person_search_rounded, color: AppColors.textMuted),
            suffixIcon: _selectedCustomer != null
                ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                : _isSearchingCustomer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brand500,
                          ),
                        ),
                      )
                    : null,
            filled: true,
            fillColor: AppColors.of(context).surface1,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.of(context).borderSubtle, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.of(context).borderSubtle, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brand500, width: 2),
            ),
          ),
          onChanged: (v) {
            setState(() {
              _selectedCustomer = null;
              _showSuggestions = true;
            });
            _onCustomerSearchChanged(v);
          },
          onTap: () {
            setState(() => _showSuggestions = true);
            if (_customerSearchController.text.isEmpty) {
              setState(() => _suggestions = List.from(_recentCustomers));
            }
          },
          validator: (_) => _selectedCustomer == null ? 'الرجاء اختيار العميل' : null,
        ),
        if (_showSuggestions && (_suggestions.isNotEmpty || _isSearchingCustomer))
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isSearchingCustomer && _suggestions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.brand500,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length + 1,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.of(context).borderSubtle,
                    ),
                    itemBuilder: (ctx, index) {
                      // Last item: "Add new customer" shortcut
                      if (index == _suggestions.length) {
                        return ListTile(
                          leading: const Icon(
                            Icons.person_add_rounded,
                            color: AppColors.brand500,
                          ),
                          title: Text(
                            'إضافة عميل جديد',
                            style: AppTextStyles.sm.copyWith(color: AppColors.brand500),
                          ),
                          onTap: () async {
                            setState(() => _showSuggestions = false);
                            _customerFocusNode.unfocus();
                            final newCustomer = await Navigator.push<Customer>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddCustomerScreen(),
                              ),
                            );
                            if (newCustomer != null && mounted) {
                              setState(() {
                                _selectedCustomer = newCustomer;
                                _customerSearchController.text = newCustomer.name;
                                _recentCustomers.insert(0, newCustomer);
                                if (_recentCustomers.length > 5) _recentCustomers.removeLast();
                              });
                            }
                          },
                        );
                      }
                      // Regular customer entry
                      final customer = _suggestions[index];
                      final showHistoryIcon = _customerSearchController.text.isEmpty;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.brand500.withOpacity(0.15),
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.brand500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: AppTextStyles.sm.copyWith(
                            color: AppColors.of(ctx).textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          customer.phone,
                          style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary),
                        ),
                        trailing: showHistoryIcon
                            ? Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCustomer = customer;
                            _customerSearchController.text = customer.name;
                            _showSuggestions = false;
                            _recentCustomers.removeWhere((c) => c.id == customer.id);
                            _recentCustomers.insert(0, customer);
                            if (_recentCustomers.length > 5) _recentCustomers.removeLast();
                          });
                          _customerFocusNode.unfocus();
                        },
                      );
                    },
                  ),
          ),
      ],
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