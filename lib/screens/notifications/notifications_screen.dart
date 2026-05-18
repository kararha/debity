import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<PendingNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    debugPrint('[NotificationsScreen] _loadNotifications() — start');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Query directly — does NOT mark rows as sent, so the inbox stays persistent
      final rows = await Supabase.instance.client
          .from('pending_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (rows as List)
          .map((e) => PendingNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('[NotificationsScreen] got ${notifications.length} notifications');
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[NotificationsScreen] ERROR: $e');
      debugPrint('[NotificationsScreen] STACK: $stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runDailyCheck() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final loc = AppLocalizations.of(context);
      setState(() => _isLoading = true);

      final response = await _apiService.runDailyReminderCheck();

      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.newNotificationsCreated(response.summary.totalNotifications)),
          backgroundColor: AppColors.success,
        ),
      );

      _loadNotifications();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  Future<void> _checkOverdue() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final loc = AppLocalizations.of(context);
      setState(() => _isLoading = true);

      final response = await _apiService.checkOverdueInstallments();

      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.updatedOverdueSummary(response.newlyOverdue, response.totalOverdue)),
          backgroundColor: response.newlyOverdue > 0
              ? AppColors.warning
              : AppColors.success,
        ),
      );

      _loadNotifications();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'daily',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('تحديث التذكيرات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'overdue',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber),
                    SizedBox(width: 8),
                    Text('فحص المتأخرات'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'daily') {
                _runDailyCheck();
              } else if (value == 'overdue') {
                _checkOverdue();
              }
            },
          ),
        ],
      ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _notifications.isEmpty
                  ? _buildEmptyView()
                  : _buildNotificationsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).loadFailed, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color.fromRGBO((AppColors.success.toARGB32() >> 16) & 0xFF, (AppColors.success.toARGB32() >> 8) & 0xFF, AppColors.success.toARGB32() & 0xFF, 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: Color.fromRGBO((AppColors.success.toARGB32() >> 16) & 0xFF, (AppColors.success.toARGB32() >> 8) & 0xFF, AppColors.success.toARGB32() & 0xFF, 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noNotifications,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).allClearMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _runDailyCheck,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).refreshReminders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final overdueNotifications = _notifications.where((n) => n.type == 'overdue').toList();
    final todayNotifications = _notifications.where((n) => n.type == 'reminder_today').toList();
    final tomorrowNotifications = _notifications.where((n) => n.type == 'reminder_tomorrow').toList();
    final otherNotifications = _notifications
        .where((n) => n.type != 'overdue' && n.type != 'reminder_today' && n.type != 'reminder_tomorrow')
        .toList();

    // Flatten lists
    final List<dynamic> flattened = [];
    if (overdueNotifications.isNotEmpty) {
      flattened.add({'type': 'header', 'title': 'أقساط متأخرة', 'icon': Icons.warning_amber_rounded, 'color': AppColors.error, 'count': overdueNotifications.length});
      flattened.addAll(overdueNotifications.map((n) => {'type': 'item', 'data': n, 'color': AppColors.error}));
    }
    if (todayNotifications.isNotEmpty) {
      flattened.add({'type': 'header', 'title': 'مستحقة اليوم', 'icon': Icons.today, 'color': AppColors.warning, 'count': todayNotifications.length});
      flattened.addAll(todayNotifications.map((n) => {'type': 'item', 'data': n, 'color': AppColors.warning}));
    }
    if (tomorrowNotifications.isNotEmpty) {
      flattened.add({'type': 'header', 'title': 'مستحقة غداً', 'icon': Icons.event, 'color': AppColors.info, 'count': tomorrowNotifications.length});
      flattened.addAll(tomorrowNotifications.map((n) => {'type': 'item', 'data': n, 'color': AppColors.info}));
    }
    if (otherNotifications.isNotEmpty) {
      flattened.add({'type': 'header', 'title': 'إشعارات أخرى', 'icon': Icons.notifications, 'color': AppColors.primaryColor, 'count': otherNotifications.length});
      flattened.addAll(otherNotifications.map((n) => {'type': 'item', 'data': n, 'color': AppColors.primaryColor}));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: flattened.length,
        itemBuilder: (context, index) {
          final item = flattened[index];
          if (item['type'] == 'header') {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index != 0) const SizedBox(height: 16),
                _buildSectionHeader(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  count: item['count'] as int,
                ),
                const SizedBox(height: 12),
              ],
            );
          } else {
            return _buildNotificationCard(item['data'] as PendingNotification, item['color'] as Color);
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color.fromRGBO((color.toARGB32() >> 16) & 0xFF, (color.toARGB32() >> 8) & 0xFF, color.toARGB32() & 0xFF, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color.fromRGBO((color.toARGB32() >> 16) & 0xFF, (color.toARGB32() >> 8) & 0xFF, color.toARGB32() & 0xFF, 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(PendingNotification notification, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color.fromRGBO((color.toARGB32() >> 16) & 0xFF, (color.toARGB32() >> 8) & 0xFF, color.toARGB32() & 0xFF, 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  _formatTime(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormatter.formatDate(dateTime);
  }
}
