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
import '../../core/l10n/app_localizations.dart';

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
          .order('installment_number', ascending: true);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(AppLocalizations.of(context).deleteDebtTitle,
            style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold)),
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
            child: Text(AppLocalizations.of(context).delete, style: AppTextStyles.base.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold)),
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
        backgroundColor: AppColors.surface0,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
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
                padding: const EdgeInsets.all(AppSpacing.pageH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: AppSpacing.sp24),
                    _buildStatsGrid(),
                    const SizedBox(height: AppSpacing.sp32),
                    _buildInstallmentsHeader(),
                    const SizedBox(height: AppSpacing.sp16),
                    _buildInstallmentsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brand500, AppColors.brand400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand500.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.sp16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_debt.itemName, style: AppTextStyles.xl.copyWith(fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: AppSpacing.sp4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          _debt.customerName ?? AppLocalizations.of(context).customerLabel,
                          style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
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
              Text(AppLocalizations.of(context).progressLabel, style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              Text('${_debt.progressPercentage.toStringAsFixed(0)}%', style: AppTextStyles.sm.copyWith(fontWeight: FontWeight.bold, color: AppColors.brand600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sp8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: _debt.progressPercentage / 100,
              minHeight: 10,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(
                _debt.progressPercentage >= 100 ? AppColors.success : AppColors.brand500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: AppSpacing.sp12,
      crossAxisSpacing: AppSpacing.sp12,
      children: [
        StatCard(
          label: AppLocalizations.of(context).sellingPrice,
          value: NumberFormatter.formatCurrency(_debt.sellingPrice),
          icon: Icons.payments_rounded,
        ),
        StatCard(
          label: AppLocalizations.of(context).downPayment,
          value: NumberFormatter.formatCurrency(_debt.downPayment),
          icon: Icons.south_west_rounded,
        ),
        StatCard(
          label: AppLocalizations.of(context).totalPaid,
          value: NumberFormatter.formatCurrency(_debt.paidAmount),
          valueColor: AppColors.success,
          icon: Icons.verified_rounded,
        ),
        StatCard(
          label: AppLocalizations.of(context).remaining,
          value: NumberFormatter.formatCurrency(_debt.remainingAmount),
          valueColor: _debt.remainingAmount > 0 ? AppColors.danger : AppColors.textPrimary,
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }

  Widget _buildInstallmentsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).installmentsLabel,
          style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_installments.any((i) => i.status == InstallmentStatus.overdue))
          StatusBadge.fromString('overdue'),
      ],
    );
  }

  Widget _buildInstallmentsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _installments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp12),
      itemBuilder: (context, index) {
        final installment = _installments[index];
        final isPaid = installment.status == InstallmentStatus.paid;
        
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: isPaid ? AppColors.success.withValues(alpha: 0.2) : AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface2,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: isPaid
                          ? const Icon(Icons.check_rounded, color: AppColors.success, size: 20)
                          : Text('${installment.installmentNumber}', style: AppTextStyles.base.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: AppSpacing.sp16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            NumberFormatter.formatCurrency(installment.amount),
                            style: AppTextStyles.base.copyWith(fontWeight: FontWeight.bold, color: isPaid ? AppColors.textSecondary : AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppLocalizations.of(context).dueDateLabel}: ${DateFormatter.formatDate(installment.dueDate)}',
                            style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.fromString(installment.status.name),
                    if (!isPaid) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}