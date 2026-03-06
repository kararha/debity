import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart' hide AppDurations, AppIconSizes, AppSpacing, AppRadius;
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_item_tile.dart';
import '../../core/widgets/skeleton_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/customer.dart';
import '../../models/debt.dart';
import '../debts/add_debt_screen.dart';
import '../debts/debt_details_screen.dart';
import 'add_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final _supabase = Supabase.instance.client;
  List<Debt> _debts = [];
  bool _isLoading = true;
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('debts')
          .select()
          .eq('customer_id', _customer.id!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _debts = (response as List).map((json) => Debt.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context).failedLoadDebts}: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        title: Text(AppLocalizations.of(context).deleteCustomerTitle, style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          AppLocalizations.of(context).deleteCustomerConfirm.replaceAll('{name}', _customer.name),
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
      await _supabase.from('customers').delete().eq('id', _customer.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).deleteSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context).deleteError}: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _callCustomer() async {
    final uri = Uri.parse('tel:${_customer.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _messageCustomer() async {
    final uri = Uri.parse('sms:${_customer.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _whatsappCustomer() async {
    final phone = _customer.phone.startsWith('0')
        ? '964${_customer.phone.substring(1)}'
        : _customer.phone;
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDebt = 0;
    double totalPaid = 0;
    int activeDebts = 0;
    for (var debt in _debts) {
      totalDebt += debt.originalPrice;
      totalPaid += debt.downPayment;
      if (debt.status.name != 'completed' && debt.status.name != 'cancelled') {
        activeDebts++;
      }
    }
    double totalRemaining = totalDebt - totalPaid;

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: Text('تفاصيل العميل', style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textMuted),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerScreen(customer: _customer),
                ),
              );
              if (result is Customer) {
                setState(() => _customer = result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH, vertical: AppSpacing.sp24),
        child: Column(
          children: [
            // Profile Card Let's make it beautiful
            AppCard(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.brand500.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brand500, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _customer.name.isNotEmpty ? _customer.name[0].toUpperCase() : '?',
                      style: AppTextStyles.xl3.copyWith(color: AppColors.brand400, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp16),
                  Text(_customer.name, style: AppTextStyles.xl2.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sp4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.sp4),
                      Text(_customer.phone, style: AppTextStyles.base.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  if ((_customer.address ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sp8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.sp4),
                        Text(_customer.address!, style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sp24),
                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAction(Icons.call_rounded, AppLocalizations.of(context).call, _callCustomer),
                      const SizedBox(width: AppSpacing.sp16),
                      _buildQuickAction(Icons.message_rounded, AppLocalizations.of(context).message, _messageCustomer),
                      const SizedBox(width: AppSpacing.sp16),
                      _buildQuickAction(Icons.chat_rounded, AppLocalizations.of(context).whatsapp, _whatsappCustomer),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              mainAxisSpacing: AppSpacing.sp16,
              crossAxisSpacing: AppSpacing.sp16,
              children: [
                StatCard(
                  label: AppLocalizations.of(context).totalDebts,
                  value: NumberFormatter.formatCurrency(totalDebt),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                StatCard(
                  label: AppLocalizations.of(context).totalPaid,
                  value: NumberFormatter.formatCurrency(totalPaid),
                  valueColor: AppColors.success,
                  icon: Icons.payments_rounded,
                ),
                StatCard(
                  label: AppLocalizations.of(context).remaining,
                  value: NumberFormatter.formatCurrency(totalRemaining),
                  valueColor: totalRemaining > 0 ? AppColors.danger : AppColors.textPrimary,
                  icon: Icons.timeline_rounded,
                ),
                StatCard(
                  label: AppLocalizations.of(context).activeDebts,
                  value: '$activeDebts',
                  icon: Icons.pending_actions_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Debts List
            SectionPanel(
              title: AppLocalizations.of(context).debtsTitle,
              child: _isLoading 
                  ? buildListSkeleton(count: 3)
                  : _debts.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.sp32),
                              child: Text(AppLocalizations.of(context).noDebtsForCustomer, style: TextStyle(color: AppColors.textMuted)),
                          ),
                        )
                      : DebtListView(
                          itemCount: _debts.length,
                          itemBuilder: (context, i) {
                            final debt = _debts[i];
                            return DebtListItem(
                              primaryText: debt.customerName ?? 'دين',
                              secondaryText: 'تاريخ الإنشاء: ',
                              amount: NumberFormatter.formatCurrency(debt.remainingAmount),
                              amountColor: debt.remainingAmount > 0 ? AppColors.warning : AppColors.success,
                              trailing: StatusBadge.fromString(debt.status.name),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DebtDetailsScreen(debt: debt),
                                  ),
                                );
                                _loadDebts();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDebtScreen(customer: _customer),
            ),
          );
          if (result == true) {
            _loadDebts();
          }
        },
        backgroundColor: AppColors.brand500,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(label, style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
