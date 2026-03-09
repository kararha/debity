import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/api_service.dart';
import 'auth/auth_screen.dart';
import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart' hide AppSpacing, AppRadius;
import '../core/widgets/app_card.dart';
import '../core/widgets/debity_app_bar.dart';
import '../core/widgets/debity_button.dart';
import '../core/widgets/list_item_tile.dart';
import '../core/widgets/skeleton_widget.dart';
import '../core/widgets/status_badge.dart';
import 'customers/customers_screen.dart';
import 'debts/debts_screen.dart';
import 'notifications/notifications_screen.dart';
import 'settings/settings_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
// HomeScreen — 4-tab shell
// ═══════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final StreamSubscription<AuthState> _authSub;

  // 5 tabs: Dashboard, Customers, Debts, Notifications, Settings
  final List<Widget> _screens = const [
    DashboardView(),
    CustomersScreen(),
    DebtsScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.surface0,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _DebityBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Bottom navigation bar
// ═══════════════════════════════════════════════════════════════════════

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _DebityBottomNav extends StatelessWidget {
  const _DebityBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static List<_NavItem> _itemsFor(BuildContext context) => [
        _NavItem(icon: Icons.home_outlined, label: AppLocalizations.of(context).navHome),
        _NavItem(icon: Icons.people_outline, label: AppLocalizations.of(context).navCustomers),
        _NavItem(icon: Icons.receipt_long_outlined, label: AppLocalizations.of(context).navDebts),
        _NavItem(icon: Icons.notifications_outlined, label: AppLocalizations.of(context).navNotifications),
        _NavItem(icon: Icons.settings_outlined, label: AppLocalizations.of(context).navSettings),
      ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavH,
          child: Row(
            children: List.generate(_itemsFor(context).length, (i) {
              final item = _itemsFor(context)[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with premium active pill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brand500.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            selected ? _getActiveIcon(item.icon) : item.icon,
                            size: 24,
                            color: selected
                                ? AppColors.brand500
                                : c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTextStyles.navLabel.copyWith(
                            color: selected
                                ? AppColors.brand500
                                : c.textMuted,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Helper to switch to solid icons when selected for a premium feel
  IconData _getActiveIcon(IconData outlinedIcon) {
    if (outlinedIcon == Icons.home_outlined) return Icons.home_rounded;
    if (outlinedIcon == Icons.people_outline) return Icons.people_rounded;
    if (outlinedIcon == Icons.receipt_long_outlined) return Icons.receipt_long_rounded;
    if (outlinedIcon == Icons.notifications_outlined) return Icons.notifications_rounded;
    if (outlinedIcon == Icons.settings_outlined) return Icons.settings_rounded;
    return outlinedIcon;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Dashboard View
// ═══════════════════════════════════════════════════════════════════════

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ApiService _apiService = ApiService();
  Statistics? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _apiService.getStatistics();
      if (mounted) setState(() { _statistics = response.statistics; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.surface0,
      appBar: DebityAppBar(
        userInitial: _userInitial,
      ),
      body: Column(
        children: [
          // Optional divider under App Bar
          Container(height: 1.0, color: c.borderSubtle.withOpacity(0.5)),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  String? get _userInitial {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String?;
    return name?.isNotEmpty == true ? name![0] : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : null);
  }

  // ── Skeleton ───────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH, vertical: AppSpacing.sp24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 220, height: 32),
          const SizedBox(height: 8),
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: AppSpacing.sp32),
          buildStatGridSkeleton(),
          const SizedBox(height: AppSpacing.sp24),
          buildListSkeleton(count: 4),
        ],
      ),
    );
  }

  // ── Premium Error State ────────────────────────────────────────────
  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sp32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.sp24),
          Text(
            AppLocalizations.of(context).loadFailed,
            style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            _error ?? '',
            style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sp32),
          DebityPrimaryButton(
            label: AppLocalizations.of(context).retry,
            onPressed: _loadStatistics,
          ),
        ],
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────
  Widget _buildContent() {
    final stats = _statistics!;
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: AppColors.brand500,
      backgroundColor: AppColors.of(context).surface0,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH, AppSpacing.sp24,
          AppSpacing.pageH, AppSpacing.sp40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dashboard Title ─────────────────────────────────────
            Text(
              AppLocalizations.of(context).dashboardTitle,
              style: AppTextStyles.base.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sp32),

            // ── Overdue alert ───────────────────────────────────────
            if (stats.overdueCount > 0) ...[
              _OverdueAlert(count: stats.overdueCount),
              const SizedBox(height: AppSpacing.sp24),
            ],

            // ── Stat cards grid (2 columns) ─────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sp16, // Unified spacing
              crossAxisSpacing: AppSpacing.sp16,
              childAspectRatio: 1.45,
              children: [
                StatCard(
                  label: AppLocalizations.of(context).statTotalDebts,
                  value: NumberFormatter.formatCurrency(stats.totalDebts),
                  icon: Icons.account_balance_wallet_rounded, // Swapped to solid
                  valueColor: AppColors.brand500,
                ),
                StatCard(
                  label: AppLocalizations.of(context).statTotalRemaining,
                  value: NumberFormatter.formatCurrency(stats.totalRemaining),
                  icon: Icons.pending_actions_rounded,
                  valueColor: AppColors.warning,
                ),
                StatCard(
                  label: AppLocalizations.of(context).statTotalPaid,
                  value: NumberFormatter.formatCurrency(stats.totalPaid),
                  icon: Icons.check_circle_rounded,
                  valueColor: AppColors.success,
                ),
                StatCard(
                  label: AppLocalizations.of(context).statOverdueInstallments,
                  value: '${stats.overdueCount}',
                  icon: Icons.schedule_rounded,
                  valueColor: stats.overdueCount > 0
                      ? AppColors.danger
                      : AppColors.of(context).textPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp16),

            // ── Active / Completed mini-row ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MiniStatTile(
                    label: AppLocalizations.of(context).miniActiveDebts,
                    value: '${stats.activeDebts}',
                    color: AppColors.warning,
                    icon: Icons.bolt_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp16),
                Expanded(
                  child: _MiniStatTile(
                    label: AppLocalizations.of(context).miniCompletedDebts,
                    value: '${stats.completedDebts}',
                    color: AppColors.success,
                    icon: Icons.task_alt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Overdue installments panel ──────────────────────────
            if (stats.overdueCount > 0) ...[
              SectionPanel(
                title: AppLocalizations.of(context).sectionOverdueInstallments,
                trailing: OverdueBadge(count: stats.overdueCount),
                child: stats.topCustomers.isEmpty
                    ? _emptyState(AppLocalizations.of(context).noOverdueInstallments, Icons.check_circle_outline)
                    : DebtListView(
                        itemCount: stats.topCustomers.length,
                        itemBuilder: (_, i) {
                          final c = stats.topCustomers[i];
                          return DebtListItem(
                            primaryText: '${AppLocalizations.of(context).customerLabel} ...${c.customerId.length >= 8 ? c.customerId.substring(0, 8) : c.customerId}',
                            secondaryText: AppLocalizations.of(context).remainingAmountLabel,
                            amount: NumberFormatter.formatCurrency(c.remainingAmount),
                            amountColor: AppColors.danger,
                            trailing: StatusBadge.fromString('overdue'),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],

            // ── Recent payments panel ───────────────────────────────
            SectionPanel(
              title: AppLocalizations.of(context).sectionTopDebtors,
              child: stats.topCustomers.isEmpty
                  ? _emptyState(AppLocalizations.of(context).noData, Icons.analytics_outlined)
                  : DebtListView(
                      itemCount: stats.topCustomers.length,
                      itemBuilder: (_, i) {
                        final c = stats.topCustomers[i];
                        return DebtListItem(
                          primaryText: '${AppLocalizations.of(context).customerLabel} #${i + 1}',
                          secondaryText: AppLocalizations.of(context).remainingAmountLabel,
                          amount: NumberFormatter.formatCurrency(c.remainingAmount),
                          amountColor: AppColors.warning,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Upgraded Empty State to match the rest of the app
  Widget _emptyState(String msg, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.of(context).textMuted.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.sp12),
            Text(msg, style: AppTextStyles.base.copyWith(color: AppColors.of(context).textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Greeting removed per UX request.
}

// ─── Overdue alert banner ─────────────────────────────────────────────

class _OverdueAlert extends StatelessWidget {
  const _OverdueAlert({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp20, vertical: AppSpacing.sp16,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
          ),
          const SizedBox(width: AppSpacing.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنبيه أقساط متأخرة', // Ideally localize this
                  style: AppTextStyles.sm.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).overdueAlert.replaceAll('{count}', '$count'),
                  style: AppTextStyles.base.copyWith(color: AppColors.danger.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: AppColors.danger, size: 24), // Left for Arabic RTL
        ],
      ),
    );
  }
}

// ─── Mini stat tile ───────────────────────────────────────────────────

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.label, required this.value, required this.color, required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).borderSubtle.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.xl.copyWith(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}