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
  List<Installment> _allInstallments = [];
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
          (i.status == InstallmentStatus.pending && i.dueDate.isBefore(DateTime.now())))
      .toList();

  List<Installment> get _paidInstallments => _filteredInstallments
      .where((i) => i.status == InstallmentStatus.paid)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF4F6FB);
    final surfaceColor = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A3A), const Color(0xFF0D0D20)]
                    : [AppColors.primaryColor, const Color(0xFF1565C0)],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(loc.installmentsTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20), onPressed: _loadInstallments),
              ]),
              const SizedBox(height: 10), 
              _buildPeriodFilter(isDark, surfaceColor),
              const SizedBox(height: 10),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: loc.tabLabel('installments_tab_all', _filteredInstallments.length)),
                  Tab(text: loc.tabLabel('installments_tab_pending', _pendingInstallments.length)),
                  Tab(text: loc.tabLabel('installments_tab_overdue', _overdueInstallments.length)),
                  Tab(text: loc.tabLabel('installments_tab_paid', _paidInstallments.length)),
                  ],
              ),
            ]),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
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

  Widget _buildPeriodFilter(bool isDark, Color surface) {
    final loc = AppLocalizations.of(context);
    final filters = [('all', loc.filterAll), ('today', loc.filterToday), ('week', loc.filterWeek), ('month', loc.filterMonth)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((f) {
        final isSelected = _filterPeriod == f.$1;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filterPeriod = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f.$2,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                )),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildErrorView() {
    final loc = AppLocalizations.of(context);
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error)),
      const SizedBox(height: 20),
      Text(loc.loadFailed, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(_error ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _loadInstallments, icon: const Icon(Icons.refresh_rounded), label: Text(loc.retry),
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    ])));
  }

  Widget _buildInstallmentList(List<Installment> installments) {
    if (installments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note,
                size: 80,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).noInstallments,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
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
      grouped.putIfAbsent(dateKey, () => []).add(installment);
    }

    return RefreshIndicator(
      onRefresh: _loadInstallments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    final groupColor = isOverdue ? AppColors.error : isToday ? AppColors.warning : AppColors.primaryColor;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(0, 14, 0, 8), child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: groupColor.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isOverdue ? Icons.warning_amber_rounded : isToday ? Icons.today_rounded : Icons.event_rounded,
              size: 13, color: groupColor),
            const SizedBox(width: 5),
            Text(title, style: TextStyle(color: groupColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(12)),
          child: Text('${installments.length}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ),
      ])),
      ...installments.map((i) => _buildInstallmentCard(i)),
    ]);
  }

  Widget _buildInstallmentCard(Installment installment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final statusColor = StatusColors.getInstallmentStatusColor(installment.status.name);
    final daysUntil = DateFormatter.daysUntil(installment.dueDate);
    final isPaid = installment.status == InstallmentStatus.paid;
    final isOverdue = !isPaid && daysUntil < 0;
    final borderColor = isPaid ? Colors.transparent : isOverdue ? AppColors.error.withOpacity(0.3) : daysUntil == 0 ? AppColors.warning.withOpacity(0.35) : Colors.transparent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isPaid ? null : () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PayInstallmentScreen(installment: installment)));
            if (result == true) _loadInstallments();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            // Date circle
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isPaid ? 0.08 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: isPaid
                ? Icon(Icons.check_circle_rounded, color: statusColor, size: 24)
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${installment.dueDate.day}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 17, height: 1)),
                    Text(_getMonthAbbr(installment.dueDate.month), style: TextStyle(color: statusColor, fontSize: 10)),
                  ])),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(installment.customerName ?? 'عميل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(installment.itemName ?? 'منتج',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('قسط ${installment.installmentNumber}', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                if (!isPaid && daysUntil != 0) ...[              
                  const SizedBox(width: 8),
                  Text(
                    daysUntil < 0 ? 'متأخر ${-daysUntil} يوم' : 'بعد $daysUntil يوم',
                    style: TextStyle(fontSize: 11, color: daysUntil < 0 ? AppColors.error : AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(NumberFormatter.formatCurrency(installment.amount),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isPaid ? AppColors.success : isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (!isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                  child: Text(AppLocalizations.of(context).payFull, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                Icon(Icons.done_all_rounded, color: AppColors.success, size: 20),
            ]),
          ])),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
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
    return months[month].substring(0, 3);
  }
}
