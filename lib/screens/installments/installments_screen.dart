import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/installment.dart';
import 'pay_installment_screen.dart';
import '../../core/l10n/app_localizations.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Installment> _allInstallments =[];
  bool _isLoading = true;
  String? _error;
  String _filterPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInstallments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInstallments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('installments')
          .select('*, debts(item_name, customers(name, phone))')
          .order('due_date');

      setState(() {
        _allInstallments = (response as List)
            .map((json) => Installment.fromJson(json))
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

  List<Installment> _filterByPeriod(List<Installment> installments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_filterPeriod) {
      case 'today':
        return installments.where((i) {
          final due = DateTime(i.dueDate.year, i.dueDate.month, i.dueDate.day);
          return due.isAtSameMomentAs(today);
        }).toList();
      case 'week':
        final weekEnd = today.add(const Duration(days: 7));
        return installments.where((i) {
          final due = DateTime(i.dueDate.year, i.dueDate.month, i.dueDate.day);
          return due.isAfter(today.subtract(const Duration(days: 1))) &&
              due.isBefore(weekEnd);
        }).toList();
      case 'month':
        return installments.where((i) {
          return i.dueDate.year == now.year && i.dueDate.month == now.month;
        }).toList();
      default:
        return installments;
    }
  }

  List<Installment> get _filteredInstallments =>
      _filterByPeriod(_allInstallments);

  List<Installment> get _pendingInstallments => _filteredInstallments
      .where((i) => i.status == InstallmentStatus.pending)
      .toList();

  List<Installment> get _overdueInstallments => _filteredInstallments
      .where((i) =>
          i.status == InstallmentStatus.overdue ||
          (i.status == InstallmentStatus.pending &&
              i.dueDate.isBefore(DateTime.now())))
      .toList();

  List<Installment> get _paidInstallments => _filteredInstallments
      .where((i) => i.status == InstallmentStatus.paid)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FE);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children:[
          _buildHeader(isDark, loc),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children:[
                          _buildInstallmentList(_filteredInstallments),
                          _buildInstallmentList(_pendingInstallments),
                          _buildInstallmentList(_overdueInstallments),
                          _buildInstallmentList(_paidInstallments),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          0, MediaQuery.of(context).padding.top + 16, 0, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ?[const Color(0xFF1A1A3A), const Color(0xFF0D0D20)]
              :[AppColors.primaryColor, const Color(0xFF1565C0)],
        ),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children:[
                Expanded(
                  child: Text(
                    loc.installmentsTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                    onPressed: _loadInstallments,
                    tooltip: 'تحديث',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPeriodFilter(isDark),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            indicatorPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs:[
              Tab(text: loc.tabLabel('installments_tab_all', _filteredInstallments.length)),
              Tab(text: loc.tabLabel('installments_tab_pending', _pendingInstallments.length)),
              Tab(text: loc.tabLabel('installments_tab_overdue', _overdueInstallments.length)),
              Tab(text: loc.tabLabel('installments_tab_paid', _paidInstallments.length)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter(bool isDark) {
    final loc = AppLocalizations.of(context);
    final filters =[
      ('all', loc.filterAll),
      ('today', loc.filterToday),
      ('week', loc.filterWeek),
      ('month', loc.filterMonth)
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterPeriod == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8), // Adjusted for RTL
            child: GestureDetector(
              onTap: () => setState(() => _filterPeriod = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorView() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              loc.loadFailed,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadInstallments,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(loc.retry),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentList(List<Installment> installments) {
    if (installments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).noInstallments,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Group by date
    final grouped = <String, List<Installment>>{};
    for (final installment in installments) {
      final dateKey = _getDateGroupKey(installment.dueDate);
      grouped.putIfAbsent(dateKey, () =>[]).add(installment);
    }

    return RefreshIndicator(
      onRefresh: _loadInstallments,
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final items = grouped[dateKey]!;
          return _buildDateGroup(dateKey, items);
        },
      ),
    );
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = targetDate.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';
    if (diff < -1) return 'متأخرة';
    if (diff <= 7) return 'هذا الأسبوع';
    return DateFormatter.formatMonthYear(date);
  }

  Widget _buildDateGroup(String title, List<Installment> installments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = title == 'متأخرة' || title == 'أمس';
    final isToday = title == 'اليوم';
    
    final groupColor = isOverdue
        ? AppColors.error
        : isToday
            ? AppColors.warning
            : AppColors.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Row(
            children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Icon(
                      isOverdue
                          ? Icons.warning_amber_rounded
                          : isToday
                              ? Icons.today_rounded
                              : Icons.event_rounded,
                      size: 14,
                      color: groupColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: groupColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${installments.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...installments.map((i) => _buildInstallmentCard(i)),
      ],
    );
  }

  Widget _buildInstallmentCard(Installment installment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    
    // Assuming StatusColors exists in your project. If not, use standard logic.
    final statusColor = StatusColors.getInstallmentStatusColor(installment.status.name);
    
    final daysUntil = DateFormatter.daysUntil(installment.dueDate);
    final isPaid = installment.status == InstallmentStatus.paid;
    final isOverdue = !isPaid && daysUntil < 0;

    final borderColor = isPaid
        ? Colors.transparent
        : isOverdue
            ? AppColors.error.withValues(alpha: 0.4)
            : daysUntil == 0
                ? AppColors.warning.withValues(alpha: 0.4)
                : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isPaid
              ? null
              : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PayInstallmentScreen(installment: installment),
                    ),
                  );
                  if (result == true) _loadInstallments();
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children:[
                // Date/Status Circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isPaid ? 0.08 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isPaid
                        ? Icon(Icons.check_circle_rounded,
                            color: statusColor, size: 28)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Text(
                                '${installment.dueDate.day}',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                _getMonthAbbr(installment.dueDate.month),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(
                        installment.customerName ?? 'عميل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        installment.itemName ?? 'منتج',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children:[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'قسط ${installment.installmentNumber}',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!isPaid && daysUntil != 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              daysUntil < 0
                                  ? 'متأخر ${-daysUntil} يوم'
                                  : 'بعد $daysUntil يوم',
                              style: TextStyle(
                                fontSize: 12,
                                color: daysUntil < 0
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount and Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:[
                    Text(
                      NumberFormatter.formatCurrency(installment.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPaid
                            ? AppColors.success
                            : isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:[
                              AppColors.primaryColor,
                              AppColors.primaryColor.withValues(alpha: 0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:[
                            BoxShadow(
                              color: AppColors.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          AppLocalizations.of(context).payFull,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.done_all_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months =[
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month].length >= 3 
      ? months[month].substring(0, 3) 
      : months[month];
  }
}