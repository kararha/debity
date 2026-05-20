import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart' hide AppSpacing;
import '../../models/debt.dart';
import 'debt_details_screen.dart';
import 'add_debt_screen.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/widgets/skeleton_widget.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Debt> _allDebts = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDebts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.toLowerCase());
      }
    });
  }

  Future<void> _loadDebts() async {
    if (!mounted) return;
    
    if (mounted) setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('debts')
          .select('*, customers(name, phone)')
          .order('created_at', ascending: false);

      if (!mounted) return;
      
      if (mounted) setState(() {
        _allDebts = (response as List)
            .map((json) => Debt.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Debt> get _filteredDebts {
    var debts = _allDebts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      debts = debts.where((debt) {
        return debt.itemName.toLowerCase().contains(_searchQuery) ||
            (debt.customerName?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return debts;
  }

  List<Debt> get _activeDebts =>
      _filteredDebts.where((d) => d.status == DebtStatus.active).toList();

  List<Debt> get _completedDebts =>
      _filteredDebts.where((d) => d.status == DebtStatus.completed).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.of(context).surface0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header with tabs
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              MediaQuery.of(context).padding.top + AppSpacing.sp16,
              AppSpacing.pageH,
              0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.primaryColor, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).debtsTitle,
                        style: AppTextStyles.xl2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Refresh button removed per UI update
                  ],
                ),
                const SizedBox(height: AppSpacing.sp16),
                DebityTextField(
                  controller: _searchController,
                  hintText: AppLocalizations.of(context).debtsSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _searchController.clear,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.sp8),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color.fromARGB(255, 253, 252, 252),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                  labelStyle: AppTextStyles.sm.copyWith(fontWeight: FontWeight.bold),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: AppLocalizations.of(context).tabLabel('tab_all', _filteredDebts.length)),
                    Tab(text: AppLocalizations.of(context).tabLabel('tab_active', _activeDebts.length)),
                    Tab(text: AppLocalizations.of(context).tabLabel('tab_completed', _completedDebts.length)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildSkeletonList()
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDebtList(_filteredDebts),
                          _buildDebtList(_activeDebts),
                          _buildDebtList(_completedDebts),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: AppLocalizations.of(context).addDebt,
            button: true,
            child: Tooltip(
              message: AppLocalizations.of(context).addDebt,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand500, AppColors.brand400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand500.withValues(alpha: 0.28),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                    );
                    if (result == true) _loadDebts();
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).addDebt,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sp20),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.sp20),
            Text(
              AppLocalizations.of(context).loadFailed,
              style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sp8),
            Text(
              _error ?? '',
              style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sp24),
            FilledButton.icon(
              onPressed: _loadDebts,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).retry),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList(List<Debt> debts) {
    if (debts.isEmpty) {
      final isSearching = _searchQuery.isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sp32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sp24),
                decoration: BoxDecoration(
                  color: (isSearching ? AppColors.brand500 : AppColors.primaryColor).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearching ? Icons.search_off_rounded : Icons.account_balance_wallet_outlined,
                  size: 52,
                  color: (isSearching ? AppColors.brand500 : AppColors.primaryColor).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.sp20),
              Text(
                isSearching ? AppLocalizations.of(context).noResults : AppLocalizations.of(context).noDebts,
                style: AppTextStyles.lg.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sp8),
              Text(
                isSearching
                    ? AppLocalizations.of(context).tryDifferentSearch
                    : AppLocalizations.of(context).pressPlusAddDebt,
                style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sp24),
              if (isSearching)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear_rounded, color: AppColors.brand400),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'ar' ? 'مسح البحث' : 'Clear Search',
                    style: const TextStyle(color: AppColors.brand400),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                    );
                    if (result == true) _loadDebts();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppLocalizations.of(context).addDebt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp24,
                      vertical: AppSpacing.sp12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDebts,
      color: AppColors.brand500,
      backgroundColor: AppColors.of(context).surface1,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, AppSpacing.sp16, AppSpacing.pageH, 80),
        itemCount: debts.length,
        itemBuilder: (_, i) => _buildDebtCard(debts[i]),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH, vertical: AppSpacing.sp16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.sp16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonBox(width: 48, height: 48, radius: 12),
                  const SizedBox(width: AppSpacing.sp12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox(width: 120, height: 16, radius: 4),
                        const SizedBox(height: 6),
                        const SkeletonBox(width: 80, height: 12, radius: 4),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 60, height: 24, radius: 12),
                ],
              ),
              const SizedBox(height: AppSpacing.sp16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SkeletonBox(width: 60, height: 12, radius: 4),
                  SkeletonBox(width: 32, height: 12, radius: 4),
                ],
              ),
              const SizedBox(height: AppSpacing.sp8),
              const SkeletonBox(width: double.infinity, height: 8, radius: 4),
              const SizedBox(height: AppSpacing.sp16),
              Row(
                children: [
                  Expanded(child: const SkeletonBox(width: double.infinity, height: 40, radius: 12)),
                  const SizedBox(width: AppSpacing.sp8),
                  Expanded(child: const SkeletonBox(width: double.infinity, height: 40, radius: 12)),
                  const SizedBox(width: AppSpacing.sp8),
                  Expanded(child: const SkeletonBox(width: double.infinity, height: 40, radius: 12)),
                ],
              ),
              const SizedBox(height: AppSpacing.sp16),
              const SkeletonBox(width: double.infinity, height: 1, radius: 0),
              const SizedBox(height: AppSpacing.sp12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SkeletonBox(width: 80, height: 12, radius: 4),
                  SkeletonBox(width: 60, height: 12, radius: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = debt.progressPercentage / 100;
    final statusColor = StatusColors.getDebtStatusColor(debt.status.name);
    final statusLabel = debt.status == DebtStatus.active
        ? AppLocalizations.of(context).statusActive
        : debt.status == DebtStatus.completed
            ? AppLocalizations.of(context).statusCompleted
            : AppLocalizations.of(context).statusCancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sp16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DebtDetailsScreen(debt: debt),
            ),
          );
          if (result == true) _loadDebts();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.itemName,
                        style: AppTextStyles.lg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.of(context).textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (debt.customerName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                debt.customerName!,
                                style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.xs.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).progressLabel,
                  style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${debt.progressPercentage.toStringAsFixed(0)}%',
                  style: AppTextStyles.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progress >= 1 ? AppColors.success : AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark ? AppColors.surface2 : AppColors.of(context).borderSubtle,
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1 ? AppColors.success : AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp16),
            Row(
              children: [
                _buildAmountChip(
                  AppLocalizations.of(context).paidLabel,
                  NumberFormatter.formatCurrency(debt.paidAmount),
                  AppColors.success,
                  isDark,
                ),
                const SizedBox(width: AppSpacing.sp8),
                _buildAmountChip(
                  AppLocalizations.of(context).remainingLabel,
                  NumberFormatter.formatCurrency(debt.remainingAmount),
                  AppColors.warning,
                  isDark,
                ),
                const SizedBox(width: AppSpacing.sp8),
                _buildAmountChip(
                  AppLocalizations.of(context).totalLabel,
                  NumberFormatter.formatCurrency(debt.totalAmount),
                  AppColors.primaryColor,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp16),
            Divider(color: AppColors.of(context).borderSubtle, height: 1),
            const SizedBox(height: AppSpacing.sp12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.formatDate(debt.startDate),
                  style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.payments_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${debt.numberOfInstallments} قسط',
                  style: AppTextStyles.xs.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.sm.copyWith(fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.xs.copyWith(color: isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}