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

  Future<void> _loadCustomers() async {
    debugPrint(
      '[AddDebtScreen] _loadCustomers → fetching customers from Supabase...',
    );
    try {
      final response = await _supabase
          .from('customers')
          .select('id, name, phone, address, notes, created_at, updated_at')
          .order('name');

      debugPrint(
        '[AddDebtScreen] _loadCustomers → raw response received, count: ${(response as List).length}',
      );

      if (mounted) {
        setState(() {
          _customers = (response as List)
              .map((data) => Customer.fromJson(data))
              .toList();
          debugPrint(
            '[AddDebtScreen] _loadCustomers → parsed ${_customers.length} customers',
          );
          if (widget.customer != null) {
            debugPrint(
              '[AddDebtScreen] _loadCustomers → looking for pre-selected customer id: ${widget.customer!.id}',
            );
            final matches = _customers.where(
              (c) => c.id == widget.customer!.id,
            );
            if (matches.isNotEmpty) {
              _selectedCustomer = matches.first;
              debugPrint(
                '[AddDebtScreen] _loadCustomers → matched pre-selected: ${_selectedCustomer?.name}',
              );
            } else if (_customers.isNotEmpty) {
              _selectedCustomer = _customers.first;
              debugPrint(
                '[AddDebtScreen] _loadCustomers → no match found, defaulting to first: ${_selectedCustomer?.name}',
              );
            } else {
              debugPrint(
                '[AddDebtScreen] _loadCustomers → customers list is empty, no default set',
              );
            }
          }
          _isLoadingCustomers = false;
        });
      }
    } catch (e, st) {
      debugPrint('[AddDebtScreen] _loadCustomers ERROR: $e');
      debugPrint('[AddDebtScreen] _loadCustomers STACKTRACE: $st');
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل العملاء: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    debugPrint(
      '[AddDebtScreen] _selectDate → opening date picker, current: $_startDate',
    );
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
      debugPrint('[AddDebtScreen] _selectDate → date selected: $picked');
      setState(() => _startDate = picked);
    } else {
      debugPrint(
        '[AddDebtScreen] _selectDate → no date change (picked=$picked)',
      );
    }
  }

  Future<void> _saveDebt() async {
    debugPrint('[AddDebtScreen] _saveDebt → STEP 1: running form validation');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[AddDebtScreen] _saveDebt → STEP 1 FAILED: form is invalid');
      return;
    }
    debugPrint('[AddDebtScreen] _saveDebt → STEP 1 PASSED: form is valid');

    debugPrint(
      '[AddDebtScreen] _saveDebt → STEP 2: checking customer selection (selected=${_selectedCustomer?.name ?? "none"})',
    );
    if (_selectedCustomer == null) {
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 2 FAILED: no customer selected',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار العميل'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    debugPrint(
      '[AddDebtScreen] _saveDebt → STEP 2 PASSED: customer=${_selectedCustomer!.name}, id=${_selectedCustomer!.id}',
    );

    setState(() => _isLoading = true);

    try {
      debugPrint('[AddDebtScreen] _saveDebt → STEP 3: parsing input values');
      final downPaymentText = _downPaymentController.text.trim().replaceAll(
        ',',
        '',
      );
      final downPaymentVal = downPaymentText.isEmpty
          ? 0.0
          : double.parse(downPaymentText);
      final double sellingPrice = double.parse(
        _sellingPriceController.text.replaceAll(',', ''),
      );
      final double originalPrice = double.parse(
        _originalPriceController.text.replaceAll(',', ''),
      );
      final int numInstallments = int.parse(_installmentsController.text);
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 3 PASSED: originalPrice=$originalPrice, sellingPrice=$sellingPrice, downPayment=$downPaymentVal, installments=$numInstallments',
      );

      // 1. Insert debt
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 4: inserting debt record into Supabase',
      );
      final double totalAmount = sellingPrice - downPaymentVal;
      final double installmentAmount = numInstallments > 0
          ? (totalAmount / numInstallments)
          : totalAmount;

      // Build Debt model and use its toJson to ensure consistent keys
      final debtObj = Debt(
        customerId: _selectedCustomer!.id!,
        itemName: _itemNameController.text.trim(),
        itemDescription: _itemDescController.text.trim().isEmpty
            ? null
            : _itemDescController.text.trim(),
        originalPrice: originalPrice,
        sellingPrice: sellingPrice,
        downPayment: downPaymentVal,
        totalAmount: totalAmount,
        remainingAmount: totalAmount,
        numberOfInstallments: numInstallments,
        installmentAmount: installmentAmount,
        startDate: _startDate,
        status: DebtStatus.active,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final payload = debtObj.toJson();
      debugPrint('[AddDebtScreen] _saveDebt → payload for insert: $payload');

      final debtResponse = await _supabase
          .from('debts')
          .insert(payload)
          .select()
          .single();

      final debtId = debtResponse['id'];
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 4 PASSED: debt inserted, id=$debtId',
      );

      // 2. Build installments list
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 5: building $numInstallments installment records',
      );
      final double remainingAmount = totalAmount;
      debugPrint(
        '[AddDebtScreen] _saveDebt → remaining=$remainingAmount, per installment=$installmentAmount',
      );

      List<Map<String, dynamic>> installments = [];
      for (int i = 0; i < numInstallments; i++) {
        final dueDate = DateTime(
          _startDate.year,
          _startDate.month + i,
          _startDate.day,
        );
        debugPrint(
          '[AddDebtScreen] _saveDebt → installment #${i + 1}: due=${dueDate.toIso8601String()}, amount=$installmentAmount',
        );
        installments.add({
          'debt_id': debtId,
          'amount': installmentAmount,
          'due_date': dueDate.toIso8601String(),
          'status': 'pending',
          'installment_number': i + 1,
        });
      }
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 5 PASSED: ${installments.length} installments built',
      );

      // 3. Insert installments
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 6: inserting installments into Supabase',
      );
      await _supabase.from('installments').insert(installments);
      debugPrint(
        '[AddDebtScreen] _saveDebt → STEP 6 PASSED: installments inserted successfully',
      );

      if (mounted) {
        debugPrint(
          '[AddDebtScreen] _saveDebt → STEP 7: navigating back with success result',
        );
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة الدين بنجاح')));
      }
    } catch (e, st) {
      debugPrint('[AddDebtScreen] _saveDebt ERROR: $e');
      debugPrint('[AddDebtScreen] _saveDebt STACKTRACE: $st');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: Text('إضافة دين جديد', style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.surface0, // Adjusted for a seamless header look
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingCustomers
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand500),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageH,
                  vertical: AppSpacing.sp24,
                ),
                children: [
                  _buildCustomerSection(),
                  const SizedBox(height: AppSpacing.sp24),
                  _buildItemInfoSection(),
                  const SizedBox(height: AppSpacing.sp24),
                  _buildPricingSection(),
                  const SizedBox(height: AppSpacing.sp24),
                  _buildInstallmentsSection(),
                  const SizedBox(height: AppSpacing.sp24),
                  _buildNotesSection(),
                  const SizedBox(height: AppSpacing.sp40),
                  DebityPrimaryButton(
                    label: 'إضافة الدين',
                    isLoading: _isLoading,
                    onPressed: _saveDebt,
                  ),
                  const SizedBox(height: AppSpacing.sp24), // Extra bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildCustomerSection() {
    return SectionPanel(
      title: 'العميل',
      child: DropdownMenu<Customer>(
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
          fillColor: AppColors.surface1, // Adjusted to match custom text fields better
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
      ),
    );
  }

  Widget _buildItemInfoSection() {
    return SectionPanel(
      title: 'معلومات المنتج',
      child: Column(
        children: [
          DebityTextField(
            controller: _itemNameController,
            label: 'اسم المنتج *',
            prefixIcon: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textMuted,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'الرجاء إدخال اسم المنتج'
                : null,
          ),
          const SizedBox(height: AppSpacing.sp16),
          DebityTextField(
            controller: _itemDescController,
            label: 'وصف المنتج',
            prefixIcon: const Icon(
              Icons.description_outlined,
              color: AppColors.textMuted,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return SectionPanel(
      title: 'التسعير',
      child: Column(
        children: [
          DebityTextField(
            controller: _originalPriceController,
            label: 'السعر الأصلي * (د.ع)',
            prefixIcon: const Icon(
              Icons.sell_outlined,
              color: AppColors.textMuted,
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (double.tryParse(v.replaceAll(',', '')) == null) return 'رقم غير صحيح';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sp16),
          DebityTextField(
            controller: _sellingPriceController,
            label: 'سعر البيع * (د.ع)',
            prefixIcon: const Icon(
              Icons.point_of_sale_rounded,
              color: AppColors.textMuted,
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (double.tryParse(v.replaceAll(',', '')) == null) return 'رقم غير صحيح';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsSection() {
    return SectionPanel(
      title: 'الأقساط',
      child: Column(
        children: [
          DebityTextField(
            controller: _downPaymentController,
            label: 'الدفعة المقدمة (د.ع)',
            prefixIcon: const Icon(
              Icons.payments_outlined,
              color: AppColors.textMuted,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sp16),
          DebityTextField(
            controller: _installmentsController,
            label: 'عدد الأقساط (أشهر) *',
            prefixIcon: const Icon(
              Icons.format_list_numbered_rounded,
              color: AppColors.textMuted,
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (int.tryParse(v) == null || int.parse(v) <= 0) return 'رقم غير صحيح';
              return null;
            },
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
                prefixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.brand500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return SectionPanel(
      title: 'ملاحظات إضافية',
      child: DebityTextField(
        controller: _notesController,
        label: 'ملاحظات',
        prefixIcon: const Icon(
          Icons.sticky_note_2_outlined,
          color: AppColors.textMuted,
        ),
        maxLines: 3,
      ),
    );
  }
}