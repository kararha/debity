import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../core/theme/app_colors.dart';
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
      debugPrint('[NotificationsScreen] calling getPendingNotifications()');
      final response = await _apiService.getPendingNotifications();
      debugPrint('[NotificationsScreen] got ${response.notifications.length} notifications (count=${response.count})');
      setState(() {
        _notifications = response.notifications;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('[NotificationsScreen] ERROR: $e');
      debugPrint('[NotificationsScreen] STACK: $stack');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runDailyCheck() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _apiService.runDailyReminderCheck();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إنشاء ${response.summary.totalNotifications} إشعار جديد',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      
      _loadNotifications();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  Future<void> _checkOverdue() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _apiService.checkOverdueInstallments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث ${response.newlyOverdue} قسط متأخر\n'
            'إجمالي المتأخرات: ${response.totalOverdue}',
          ),
          backgroundColor: response.newlyOverdue > 0
              ? AppColors.warning
              : AppColors.success,
        ),
      );
      
      _loadNotifications();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
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
            Text('حدث خطأ', style: Theme.of(context).textTheme.titleMedium),
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
              label: const Text('إعادة المحاولة'),
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
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: AppColors.success.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد إشعارات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع الأقساط تحت السيطرة!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _runDailyCheck,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث التذكيرات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Group notifications by type
    final overdueNotifications =
        _notifications.where((n) => n.type == 'overdue').toList();
    final todayNotifications =
        _notifications.where((n) => n.type == 'reminder_today').toList();
    final tomorrowNotifications =
        _notifications.where((n) => n.type == 'reminder_tomorrow').toList();
    final otherNotifications = _notifications
        .where((n) =>
            n.type != 'overdue' &&
            n.type != 'reminder_today' &&
            n.type != 'reminder_tomorrow')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overdue Section
          if (overdueNotifications.isNotEmpty) ...[
            _buildSection(
              title: 'أقساط متأخرة',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              notifications: overdueNotifications,
            ),
            const SizedBox(height: 16),
          ],

          // Today Section
          if (todayNotifications.isNotEmpty) ...[
            _buildSection(
              title: 'مستحقة اليوم',
              icon: Icons.today,
              color: AppColors.warning,
              notifications: todayNotifications,
            ),
            const SizedBox(height: 16),
          ],

          // Tomorrow Section
          if (tomorrowNotifications.isNotEmpty) ...[
            _buildSection(
              title: 'مستحقة غداً',
              icon: Icons.event,
              color: AppColors.info,
              notifications: tomorrowNotifications,
            ),
            const SizedBox(height: 16),
          ],

          // Other Section
          if (otherNotifications.isNotEmpty) ...[
            _buildSection(
              title: 'إشعارات أخرى',
              icon: Icons.notifications,
              color: AppColors.primaryColor,
              notifications: otherNotifications,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<PendingNotification> notifications,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${notifications.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...notifications.map((n) => _buildNotificationCard(n, color)),
      ],
    );
  }

  Widget _buildNotificationCard(PendingNotification notification, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
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
