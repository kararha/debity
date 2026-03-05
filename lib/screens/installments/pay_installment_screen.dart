import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/installment.dart';

class PayInstallmentScreen extends StatefulWidget {
  final Installment installment;

  const PayInstallmentScreen({super.key, required this.installment});

  @override
  State<PayInstallmentScreen> createState() => _PayInstallmentScreenState();
}

class _PayInstallmentScreenState extends State<PayInstallmentScreen> {
  final _supabase = Supabase.instance.client;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _payFull = true;
  late double _remainingAmount;

  @override
  void initState() {
    super.initState();
    _remainingAmount = widget.installment.amount - widget.installment.paidAmount;
    _amountController.text = _remainingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _payInstallment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
      );
      return;
    }

    if (amount > _remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ أكبر من المتبقي')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPaidAmount = widget.installment.paidAmount + amount;
      final isFullyPaid = newPaidAmount >= widget.installment.amount;

      // Update installment
      await _supabase.from('installments').update({
        'paid_amount': newPaidAmount,
        'status': isFullyPaid ? 'paid' : 'partial',
        'paid_date': isFullyPaid ? DateTime.now().toIso8601String().split('T')[0] : null,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.installment.id!);

      // Update debt remaining amount
      final debtResponse = await _supabase
          .from('debts')
          .select('remaining_amount, total_amount')
          .eq('id', widget.installment.debtId)
          .single();

      final currentRemaining = (debtResponse['remaining_amount'] as num).toDouble();
      final newRemaining = currentRemaining - amount;

      await _supabase.from('debts').update({
        'remaining_amount': newRemaining,
        'status': newRemaining <= 0 ? 'completed' : 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.installment.debtId);

      // Create payment record
      await _supabase.from('payments').insert({
        'installment_id': widget.installment.id,
        'amount': amount,
        'payment_date': DateTime.now().toIso8601String().split('T')[0],
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullyPaid
                  ? 'تم دفع القسط بالكامل'
                  : 'تم تسجيل الدفعة الجزئية',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installment = widget.installment;
    final daysUntil = DateFormatter.daysUntil(installment.dueDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دفع القسط',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryColor, Color(0xFF1565C0)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Installment Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    daysUntil < 0
                        ? AppColors.error
                        : daysUntil == 0
                            ? AppColors.warning
                            : AppColors.primaryColor,
                    daysUntil < 0
                        ? AppColors.error.withOpacity(0.8)
                        : daysUntil == 0
                            ? AppColors.warning.withOpacity(0.8)
                            : AppColors.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${installment.installmentNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              installment.customerName ?? 'عميل',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              installment.itemName ?? 'منتج',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        label: 'قيمة القسط',
                        value: NumberFormatter.formatCurrency(installment.amount),
                      ),
                      _buildInfoItem(
                        label: 'المدفوع',
                        value:
                            NumberFormatter.formatCurrency(installment.paidAmount),
                      ),
                      _buildInfoItem(
                        label: 'المتبقي',
                        value: NumberFormatter.formatCurrency(_remainingAmount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ الاستحقاق: ${DateFormatter.formatDate(installment.dueDate)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (daysUntil != 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      daysUntil < 0
                          ? 'متأخر ${-daysUntil} يوم'
                          : 'متبقي $daysUntil يوم',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Options
            Text(
              'خيارات الدفع',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption(
                    title: 'دفع كامل',
                    subtitle: NumberFormatter.formatCurrency(_remainingAmount),
                    isSelected: _payFull,
                    onTap: () {
                      setState(() {
                        _payFull = true;
                        _amountController.text =
                            _remainingAmount.toStringAsFixed(0);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentOption(
                    title: 'دفع جزئي',
                    subtitle: 'حدد المبلغ',
                    isSelected: !_payFull,
                    onTap: () {
                      setState(() {
                        _payFull = false;
                        _amountController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Field
            Text(
              'المبلغ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              enabled: !_payFull,
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع',
                suffixText: 'د.ع',
                prefixIcon: const Icon(Icons.payments),
                filled: true,
                fillColor: _payFull
                    ? AppColors.primaryColor.withOpacity(0.05)
                    : null,
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Pay Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _payInstallment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'تأكيد الدفع',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withOpacity(0.15),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
