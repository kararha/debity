import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/installment.dart';
import '../../core/l10n/app_localizations.dart';

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
    _remainingAmount =
        widget.installment.amount - widget.installment.paidAmount;
    // Show cents to avoid rounding-up causing incorrect validation
    _amountController.text = _remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _payInstallment() async {
    final parsed = double.tryParse(_amountController.text) ?? 0;

    // Round both entered amount and remaining to 2 decimals (currency cents)
    final entered = (parsed * 100).round() / 100.0;
    final remainingRounded = (_remainingAmount * 100).round() / 100.0;

    if (entered <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).enterValidAmount)),
      );
      return;
    }

    if (entered > remainingRounded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).amountGreaterThanRemaining)),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Use the rounded entered amount for calculations to avoid fractional drift
      final newPaidAmount = widget.installment.paidAmount + entered;
      final installmentAmountRounded =
          (widget.installment.amount * 100).round() / 100.0;
      final isFullyPaid = newPaidAmount >= installmentAmountRounded;

      // Update installment
      await _supabase.from('installments').update({
        'paid_amount': newPaidAmount,
        'status': isFullyPaid ? 'paid' : 'partial',
        'paid_date': isFullyPaid
            ? DateTime.now().toIso8601String().split('T')[0]
            : null,
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

      final currentRemaining =
          (debtResponse['remaining_amount'] as num).toDouble();
      final newRemaining = currentRemaining - entered;

      await _supabase.from('debts').update({
        'remaining_amount': newRemaining,
        'status': newRemaining <= 0 ? 'completed' : 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.installment.debtId);

      // Create payment record
      await _supabase.from('payments').insert({
        'installment_id': widget.installment.id,
        'amount': entered,
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
            content: Text(isFullyPaid
                ? AppLocalizations.of(context).paymentFullSuccess
                : AppLocalizations.of(context).paymentPartialSuccess),
            backgroundColor: const Color.fromARGB(255, 6, 21, 53),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context).paymentError}: $e')),
        );
      }
    }
  }

  // Helper method to determine card color based on due date
  Color _getCardColor(int daysUntil) {
    if (daysUntil < 0) return AppColors.error;
    if (daysUntil == 0) return AppColors.warning;
    return AppColors.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final installment = widget.installment;
    final daysUntil = DateFormatter.daysUntil(installment.dueDate);
    final baseCardColor = _getCardColor(daysUntil);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).paymentTitle,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:[Color.fromARGB(255, 6, 8, 53), Color(0xFF1565C0)],
            ),
          ),
        ),
      ),
      // Action button moved to the bottom so it's always accessible
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildPayButton(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            // Modern Installment Info Card
            _buildInstallmentInfoCard(installment, daysUntil, baseCardColor),
            const SizedBox(height: 32),

            // Payment Options
            Text(
              AppLocalizations.of(context).paymentOptions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children:[
                Expanded(
                  child: _buildPaymentOption(
                    title: AppLocalizations.of(context).payFull,
                    subtitle: NumberFormatter.formatCurrency(_remainingAmount),
                    isSelected: _payFull,
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _payFull = true;
                        _amountController.text =
                            _remainingAmount.toStringAsFixed(2);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPaymentOption(
                    title: AppLocalizations.of(context).payPartial,
                    subtitle: AppLocalizations.of(context).enterAmount,
                    isSelected: !_payFull,
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _payFull = false;
                        _amountController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Amount Field
            Text(
              AppLocalizations.of(context).amountLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              enabled: !_payFull,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _payFull ? Colors.grey.shade600 : null,
              ),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).amountPaidLabel,
                suffixText: 'د.ع',
                prefixIcon: Icon(
                  Icons.payments_rounded,
                  color: _payFull ? Colors.grey : AppColors.primaryColor,
                ),
                filled: true,
                fillColor: _payFull
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).notesOptional,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 35.0), // Align icon to top
                  child: Icon(Icons.note_alt_outlined),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentInfoCard(
      Installment installment, int daysUntil, Color baseColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:[
            baseColor,
            baseColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow:[
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children:[
          // Top Row: Avatar & Name
          Row(
            children:[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${installment.installmentNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(
                      installment.customerName ?? 'عميل',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      installment.itemName ?? 'منتج',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 24),

          // Middle Row: Financial Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Expanded(
                child: _buildInfoItem(
                  label: 'قيمة القسط',
                  value: NumberFormatter.formatCurrency(installment.amount),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: _buildInfoItem(
                  label: 'المدفوع',
                  value: NumberFormatter.formatCurrency(installment.paidAmount),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: _buildInfoItem(
                  label: 'المتبقي',
                  value: NumberFormatter.formatCurrency(_remainingAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Row: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Row(
                children:[
                  Icon(Icons.calendar_month_rounded,
                      color: Colors.white.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${AppLocalizations.of(context).dueDateLabel}: ${DateFormatter.formatDate(installment.dueDate)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (daysUntil != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysUntil < 0
                        ? AppLocalizations.of(context)
                            .daysOverdue
                            .replaceAll('{n}', '${-daysUntil}')
                        : AppLocalizations.of(context)
                            .daysInFuture
                            .replaceAll('{n}', '$daysUntil'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required String label, required String value}) {
    return Column(
      children:[
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.borderColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ?[
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              :[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children:[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors:[Color(0xFF4CAF50), Color(0xFF2E7D32)], // Brighter green gradient
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow:[
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).confirmPayment,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}