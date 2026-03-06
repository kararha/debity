import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/api_service.dart';
import 'auth/auth_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart' hide AppSpacing, AppRadius;
import '../core/widgets/app_card.dart';
import '../core/widgets/debity_app_bar.dart';
import '../core/widgets/debity_button.dart';
import '../core/widgets/error_banner.dart';
import '../core/widgets/list_item_tile.dart';
import '../core/widgets/skeleton_widget.dart';
import '../core/widgets/status_badge.dart';
import 'customers/customers_screen.dart';
import 'debts/debts_screen.dart';
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

  // 4 tabs: Dashboard, Customers, Debts, Settings
  final List<Widget> _screens = const [
    DashboardView(),
    CustomersScreen(),
    DebtsScreen(),
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
    return Scaffold(
      backgroundColor: AppColors.surface0,
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

  // Items are built dynamically to allow localization
  static List<_NavItem> _itemsFor(BuildContext context) => [
        _NavItem(icon: Icons.home_outlined, label: AppLocalizations.of(context).navHome),
        _NavItem(icon: Icons.people_outline, label: AppLocalizations.of(context).navCustomers),
        _NavItem(icon: Icons.receipt_long_outlined, label: AppLocalizations.of(context).navDebts),
        _NavItem(icon: Icons.settings_outlined, label: AppLocalizations.of(context).navSettings),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
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
                        // Icon with pill indicator when active
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brand500.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.brand400
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Label
                        Text(
                          item.label,
                          style: AppTextStyles.navLabel.copyWith(
                            color: selected
                                ? AppColors.brand400
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
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
    return Scaffold(
      backgroundColor: AppColors.surface0,
      // ── App bar ────────────────────────────────────────────────────
      appBar: DebityAppBar(
        userInitial: _userInitial,
        onLogout: _handleLogout,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: _loadStatistics,
            splashRadius: 18,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  String? get _userInitial {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String?;
    return name?.isNotEmpty == true ? name![0] : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : null);
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
  }

  // ── Skeleton ───────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH, AppSpacing.sp24,
        AppSpacing.pageH, AppSpacing.sp24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 180, height: 28),
          const SizedBox(height: 6),
          const SkeletonBox(width: 130, height: 14),
          const SizedBox(height: AppSpacing.sp24),
          buildStatGridSkeleton(),
          const SizedBox(height: AppSpacing.sp24),
          buildListSkeleton(count: 4),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ErrorBanner(message: _error!, onDismiss: _loadStatistics),
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
      backgroundColor: AppColors.surface2,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH, AppSpacing.sp24,
          AppSpacing.pageH, AppSpacing.sp40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page title ──────────────────────────────────────────
            Text(
              'لوحة التحكم',
              style: AppTextStyles.xl2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sp4),
            Text(
              _greeting(),
              style: AppTextStyles.base.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sp24),

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
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                StatCard(
                  label: 'إجمالي الديون',
                  value: NumberFormatter.formatCurrency(stats.totalDebts),
                  icon: Icons.account_balance_wallet_outlined,
                  valueColor: AppColors.brand400,
                ),
                StatCard(
                  label: 'المبلغ المتبقي',
                  value: NumberFormatter.formatCurrency(stats.totalRemaining),
                  icon: Icons.pending_actions_outlined,
                  valueColor: AppColors.warning,
                ),
                StatCard(
                  label: 'المبلغ المدفوع',
                  value: NumberFormatter.formatCurrency(stats.totalPaid),
                  icon: Icons.check_circle_outline,
                  valueColor: AppColors.success,
                ),
                StatCard(
                  label: 'أقساط متأخرة',
                  value: '${stats.overdueCount}',
                  icon: Icons.schedule_outlined,
                  valueColor: stats.overdueCount > 0
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp16),

            // ── Active / Completed mini-row ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MiniStatTile(
                    label: 'ديون نشطة',
                    value: '${stats.activeDebts}',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: _MiniStatTile(
                    label: 'ديون مكتملة',
                    value: '${stats.completedDebts}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Overdue installments panel ──────────────────────────
            if (stats.overdueCount > 0) ...[
              SectionPanel(
                title: 'الأقساط المتأخرة',
                trailing: OverdueBadge(count: stats.overdueCount),
                child: stats.topCustomers.isEmpty
                    ? _emptyState('لا توجد أقساط متأخرة')
                    : DebtListView(
                        itemCount: stats.topCustomers.length,
                        itemBuilder: (_, i) {
                          final c = stats.topCustomers[i];
                          return DebtListItem(
                            primaryText: 'عميل ...${c.customerId.length >= 8 ? c.customerId.substring(0, 8) : c.customerId}',
                            secondaryText: 'متبقي',
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
              title: 'أعلى العملاء مديونية',
              child: stats.topCustomers.isEmpty
                  ? _emptyState('لا توجد بيانات')
                  : DebtListView(
                      itemCount: stats.topCustomers.length,
                      itemBuilder: (_, i) {
                        final c = stats.topCustomers[i];
                        return DebtListItem(
                          primaryText: 'عميل #${i + 1}',
                          secondaryText: 'المبلغ المتبقي',
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

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp24),
      child: Center(
        child: Text(msg, style: AppTextStyles.base.copyWith(color: AppColors.textMuted)),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 17) return 'مساء الخير 🌤️';
    return 'مساء النور 🌙';
  }
}

// ─── Overdue alert banner ─────────────────────────────────────────────

class _OverdueAlert extends StatelessWidget {
  const _OverdueAlert({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1AF87171), // danger/10
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0x33F87171), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Text(
              '$count قسط متأخر — تحتاج إلى مراجعة',
              style: AppTextStyles.base.copyWith(color: AppColors.danger),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.danger, size: 18),
        ],
      ),
    );
  }
}

// ─── Mini stat tile ───────────────────────────────────────────────────

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.lg.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
