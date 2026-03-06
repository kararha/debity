import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart' hide AppDurations, AppIconSizes, AppSpacing, AppRadius;
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart' hide DebtStatus;
import '../../models/debt.dart';
import '../../models/installment.dart';

// Assuming you have PayInstallmentScreen still using old navigation
import '../installments/pay_installment_screen.dart';

class DebtDetailsScreen extends StatefulWidget {
  final Debt debt;

  const DebtDetailsScreen({super.key, required this.debt});

  @override
  State<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends State<DebtDetailsScreen> {
  final _supabase = Supabase.instance.client;
  late Debt _debt;
  List<Installment> _installments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _loadInstallments();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);

    try {
      final debtResponse = await _supabase
          .from('debts')
          .select('*, customers(name, phone)')
          .eq('id', _debt.id!)
          .single();

      final installmentsResponse = await _supabase
          .from('installments')
          .select()
          .eq('debt_id', _debt.id!)
          .order('installment_number');

      if (mounted) {
        setState(() {
          _debt = Debt.fromJson(debtResponse);
          _installments = (installmentsResponse as List)
              .map((json) => Installment.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context).failedLoadDebts}: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _deleteDebt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        title: Text(AppLocalizations.of(context).deleteDebtTitle, style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          AppLocalizations.of(context).deleteDebtConfirm.replaceAll('{name}', _debt.customerName ?? AppLocalizations.of(context).customerLabel),
          style: AppTextStyles.base,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel, style: AppTextStyles.base.copyWith(color: AppColors.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete, style: AppTextStyles.base.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('debts').delete().eq('id', _debt.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).deleteDebtSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context).deleteDebtError}: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).debtsTitle, style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            onPressed: _deleteDebt,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : RefreshIndicator(
              onRefresh: _loadInstallments,
              color: AppColors.brand500,
              backgroundColor: AppColors.surface1,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH, vertical: AppSpacing.sp24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Status
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.brand500.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: const Icon(Icons.shopping_bag_rounded, color: AppColors.brand400, size: 28),
                              ),
                              const SizedBox(width: AppSpacing.sp16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_debt.itemName, style: AppTextStyles.xl2.copyWith(fontWeight: FontWeight.bold)),
                                    if (_debt.customerName != null) ...[
                                      const SizedBox(height: AppSpacing.sp4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: AppSpacing.sp4),
                                          Text(_debt.customerName!, style: AppTextStyles.base.copyWith(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              StatusBadge.fromString(_debt.status.name),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sp24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppLocalizations.of(context).progressLabel, style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary)),
                              Text('${_debt.progressPercentage.toStringAsFixed(0)}%', style: AppTextStyles.statLabel),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sp8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: _debt.progressPercentage / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.surface2,
                              valueColor: AlwaysStoppedAnimation(
                                _debt.progressPercentage >= 100 ? AppColors.success : AppColors.brand500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      mainAxisSpacing: AppSpacing.sp16,
                      crossAxisSpacing: AppSpacing.sp16,
                      children: [
                        StatCard(
                          label: AppLocalizations.of(context).sellingPrice,
                          value: NumberFormatter.formatCurrency(_debt.sellingPrice),
                          icon: Icons.payments_rounded,
                        ),
                        StatCard(
                          label: AppLocalizations.of(context).totalPaid,
                          value: NumberFormatter.formatCurrency(_debt.paidAmount),
                          valueColor: AppColors.success,
                          icon: Icons.check_circle_rounded,
                        ),
                        StatCard(
                          label: AppLocalizations.of(context).remaining,
                          value: NumberFormatter.formatCurrency(_debt.remainingAmount),
                          valueColor: _debt.remainingAmount > 0 ? AppColors.danger : AppColors.textPrimary,
                          icon: Icons.money_off_rounded,
                        ),
                        StatCard(
                          label: AppLocalizations.of(context).installmentsLabel,
                          value: '${_debt.numberOfInstallments}',
                          icon: Icons.format_list_numbered_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // Installments
                    SectionPanel(
                      title: AppLocalizations.of(context).installmentsLabel,
                      trailing: _installments.any((i) => i.status == InstallmentStatus.overdue)
                          ? StatusBadge.fromString('overdue')
                          : null,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _installments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp8),
                        itemBuilder: (context, index) {
                          final installment = _installments[index];
                          final isPaid = installment.status == InstallmentStatus.paid;
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                onTap: isPaid ? null : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => PayInstallmentScreen(installment: installment)),
                                  );
                                  if (result == true) _loadInstallments();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sp16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isPaid ? AppColors.success.withValues(alpha: 0.15) : AppColors.surface2,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        alignment: Alignment.center,
                                        child: isPaid
                                            ? const Icon(Icons.check_rounded, color: AppColors.success)
                                            : Text('${installment.installmentNumber}', style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: AppSpacing.sp16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(NumberFormatter.formatCurrency(installment.amount), style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: AppSpacing.sp4),
                                            Text(
                                              '${AppLocalizations.of(context).dueDateLabel}: ${DateFormatter.formatDate(installment.dueDate)}',
                                              style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge.fromString(installment.status.name),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
