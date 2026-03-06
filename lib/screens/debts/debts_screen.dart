import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/debt.dart';
import 'debt_details_screen.dart';
import 'add_debt_screen.dart';
import '../../core/l10n/app_localizations.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Debt> _allDebts = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDebts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('debts')
          .select('*, customers(name, phone)')
          .order('created_at', ascending: false);

      setState(() {
        _allDebts = (response as List)
            .map((json) => Debt.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header with tabs
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).debtsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _loadDebts,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                    child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).debtsSearchHint,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: _searchController.clear,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
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
                ? const Center(child: CircularProgressIndicator())
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_debt_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
          if (result == true) _loadDebts();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context).addDebt),
        elevation: 4,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.fromRGBO((AppColors.error.toARGB32() >> 16) & 0xFF, (AppColors.error.toARGB32() >> 8) & 0xFF, AppColors.error.toARGB32() & 0xFF, 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).loadFailed,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDebts,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).retry),
              style: FilledButton.styleFrom(
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 52,
                  color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).noDebts,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).pressPlusAddDebt,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDebts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: debts.length,
        itemBuilder: (_, i) => _buildDebtCard(debts[i]),
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final progress = debt.progressPercentage / 100;
    final statusColor = StatusColors.getDebtStatusColor(debt.status.name);
    final statusLabel = debt.status == DebtStatus.active
      ? AppLocalizations.of(context).statusActive
      : debt.status == DebtStatus.completed
      ? AppLocalizations.of(context).statusCompleted
      : AppLocalizations.of(context).statusCancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, isDark ? 0.3 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DebtDetailsScreen(debt: debt),
                ),
              );
              if (result == true) _loadDebts();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.itemName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (debt.customerName != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    debt.customerName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                          decoration: BoxDecoration(
                          color: Color.fromRGBO((statusColor.toARGB32() >> 16) & 0xFF, (statusColor.toARGB32() >> 8) & 0xFF, statusColor.toARGB32() & 0xFF, 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).progressLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${debt.progressPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: progress >= 1
                              ? AppColors.success
                              : AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1
                            ? AppColors.success
                            : AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildAmountChip(
                        AppLocalizations.of(context).paidLabel,
                        NumberFormatter.formatCurrency(debt.paidAmount),
                        AppColors.success,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildAmountChip(
                        AppLocalizations.of(context).remainingLabel,
                        NumberFormatter.formatCurrency(debt.remainingAmount),
                        AppColors.warning,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildAmountChip(
                        AppLocalizations.of(context).totalLabel,
                        NumberFormatter.formatCurrency(debt.totalAmount),
                        AppColors.primaryColor,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatDate(debt.startDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.payments_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${debt.numberOfInstallments} قسط',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Color.fromRGBO((color.toARGB32() >> 16) & 0xFF, (color.toARGB32() >> 8) & 0xFF, color.toARGB32() & 0xFF, isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
