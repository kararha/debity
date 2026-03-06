import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../main.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/fcm_service.dart';
import '../auth/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();

  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  bool _overdueAlerts = true;
  int _reminderDaysBefore = 1;
  ThemeMode _themeMode = ThemeMode.system;
  String? _fcmToken;
  bool _testingNotification = false;
  bool _triggeringReminders = false;
  String _selectedLocale = AppLocale.instance.locale.languageCode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadFcmToken();
  }

  Future<void> _loadFcmToken() async {
    final token = await FCMService.getToken();
    if (mounted) setState(() => _fcmToken = token);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _overdueAlerts = prefs.getBool('overdue_alerts') ?? true;
      _reminderDaysBefore = prefs.getInt('reminder_days_before') ?? 1;
      // Sync local state with the global ThemeController.
      _themeMode = ThemeController.themeMode.value;
      // Load saved locale if present
      final saved = prefs.getString('locale');
      if (saved != null) {
        _selectedLocale = saved;
        AppLocale.instance.setLocale(saved == 'ar' ? const Locale('ar', 'IQ') : const Locale('en'));
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('overdue_alerts', _overdueAlerts);
    await prefs.setInt('reminder_days_before', _reminderDaysBefore);
    await prefs.setString('locale', _selectedLocale);
    // Theme is persisted by ThemeController — no need to save here.
  }

  void _onLocaleChanged(String code) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedLocale = code);
    await prefs.setString('locale', code);
    AppLocale.instance.setLocale(code == 'ar' ? const Locale('ar', 'IQ') : const Locale('en'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF4F6FB);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A3A), const Color(0xFF0D0D20)]
                        : [AppColors.primaryColor, const Color(0xFF1565C0)],
                  ),
                ),
                child: Padding(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 16),
                  child: Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: Color.fromRGBO(255, 255, 255, 0.15), borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28)),
                    ),
                    const SizedBox(width: 16),
                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(loc.appName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(loc.tagline, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ]),
                ),
              ),
            ),
            title: Text(loc.settingsTitle, style: const TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _buildSection(title: loc.appInfoSection, isDark: isDark, children: [
                _buildInfoTile(icon: Icons.info_outline, title: loc.versionLabel, subtitle: '1.0.0'),
                _buildInfoTile(icon: Icons.code, title: 'المطور', subtitle: 'Karar Haider'),
              ]),
              const SizedBox(height: 20),
              _buildSection(title: loc.appearanceSection, isDark: isDark, children: [
                _buildThemeTile(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                    color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                    child: const Icon(Icons.language, color: AppColors.primaryColor, size: 20),
                  ),
                  title: Text(loc.languageLabel),
                  trailing: DropdownButton<String>(
                    value: _selectedLocale,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: 'ar', child: Text(loc.languageAr)),
                      DropdownMenuItem(value: 'en', child: Text(loc.languageEn)),
                    ],
                    onChanged: (v) {
                      if (v != null) _onLocaleChanged(v);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection(title: loc.notificationsSection, isDark: isDark, children: [
                _buildSwitchTile(
                  icon: Icons.notifications_rounded,
                  title: loc.enableNotifications,
                  subtitle: loc.enableNotificationsSub,
                  value: _notificationsEnabled,
                  onChanged: _onNotificationsToggled,
                ),
                if (_notificationsEnabled) ...[
                  _buildSwitchTile(
                    icon: Icons.today_rounded,
                    title: loc.dailyReminder,
                    subtitle: loc.dailyReminderSub,
                    value: _dailyReminder,
                    onChanged: (v) { setState(() => _dailyReminder = v); _saveSettings(); },
                  ),
                  _buildSwitchTile(
                    icon: Icons.warning_amber_rounded,
                    title: loc.overdueAlerts,
                    subtitle: loc.overdueAlertsSub,
                    value: _overdueAlerts,
                    onChanged: (v) { setState(() => _overdueAlerts = v); _saveSettings(); },
                  ),
                  _buildReminderDaysTile(),
                ],
              ]),
              const SizedBox(height: 20),
              _buildSection(title: loc.testNotificationsSection, isDark: isDark, children: [
                  _buildActionTile(icon: Icons.notifications_active_rounded, title: loc.testNotificationNow, subtitle: AppLocalizations.of(context).testNotificationSub, loading: _testingNotification, onTap: _sendTestNotification),
                  _buildActionTile(icon: Icons.send_rounded, title: loc.sendDueNotifications, subtitle: AppLocalizations.of(context).sendDueNotificationsSub, loading: _triggeringReminders, onTap: _triggerUpcomingReminders),
                  _buildActionTile(icon: Icons.vpn_key_outlined, title: loc.showFcmToken, subtitle: AppLocalizations.of(context).fcmTokenSubtitle, onTap: _showFcmTokenDialog),
              ]),
              const SizedBox(height: 20),
              _buildSection(title: loc.dataSection, isDark: isDark, children: [
                _buildActionTile(icon: Icons.sync_rounded, title: loc.syncData, subtitle: AppLocalizations.of(context).syncDataSub, onTap: _syncData),
                _buildActionTile(icon: Icons.update_rounded, title: loc.updateOverdues, subtitle: AppLocalizations.of(context).updateOverduesSub, onTap: _checkOverdue),
              ]),
              const SizedBox(height: 20),
              _buildSection(title: loc.aboutSection, isDark: isDark, children: [
                _buildActionTile(icon: Icons.description_outlined, title: loc.privacyPolicy, onTap: _showPrivacyPolicy),
                _buildActionTile(icon: Icons.gavel_rounded, title: loc.termsOfService, onTap: _showTermsOfService),
                _buildActionTile(icon: Icons.help_outline_rounded, title: loc.helpAndSupport, onTap: _showHelpAndSupport),
                _buildActionTile(icon: Icons.star_outline_rounded, title: loc.rateApp, onTap: _showRateApp),
              ]),
              const SizedBox(height: 20),
              _buildSection(title: 'حساب المستخدم', isDark: isDark, children: [
                _buildActionTile(icon: Icons.logout_rounded, title: loc.logoutLabel, subtitle: AppLocalizations.of(context).logoutSub, onTap: _handleLogout, isDestructive: true),
              ]),
              const SizedBox(height: 32),
              Center(child: Column(children: [
                Text(loc.appName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontSize: 16)),
                const SizedBox(height: 4),
                Text(loc.tagline, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).copyrightLabel, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, bool isDark = false}) {
    final surface = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontSize: 13, letterSpacing: 0.3))),
      Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, isDark ? 0.2 : 0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
      ),
      title: Text(title),
      trailing: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primaryColor,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool loading = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.primaryColor;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO((color.toARGB32() >> 16) & 0xFF, (color.toARGB32() >> 8) & 0xFF, color.toARGB32() & 0xFF, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: isDestructive ? const TextStyle(color: AppColors.error) : null),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
      trailing: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.chevron_left,
              color: isDestructive ? AppColors.error : AppColors.textSecondary),
      onTap: loading ? null : onTap,
    );
  }

  Widget _buildThemeTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _themeMode == ThemeMode.dark
              ? Icons.dark_mode
              : _themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(AppLocalizations.of(context).appearanceSection),
      trailing: DropdownButton<ThemeMode>(
        value: _themeMode,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text('تلقائي'),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text('فاتح'),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text('داكن'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _themeMode = value);
            // Updates the global notifier → MaterialApp rebuilds instantly.
            ThemeController.setThemeMode(value);
          }
        },
      ),
    );
  }

  Widget _buildReminderDaysTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO((AppColors.primaryColor.toARGB32() >> 16) & 0xFF, (AppColors.primaryColor.toARGB32() >> 8) & 0xFF, AppColors.primaryColor.toARGB32() & 0xFF, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.schedule, color: AppColors.primaryColor, size: 20),
      ),
      title: Text(AppLocalizations.of(context).reminderBeforeLabel),
      trailing: DropdownButton<int>(
        value: _reminderDaysBefore,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 1, child: Text('يوم واحد')),
          DropdownMenuItem(value: 2, child: Text('يومين')),
          DropdownMenuItem(value: 3, child: Text('3 أيام')),
          DropdownMenuItem(value: 7, child: Text('أسبوع')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _reminderDaysBefore = value);
            _saveSettings();
          }
        },
      ),
    );
  }

  // ─── About section dialogs ────────────────────────────────────────────────

  void _showPrivacyPolicy() {
    _showInfoDialog(
      title: AppLocalizations.of(context).privacyPolicy,
      icon: Icons.description,
      content: AppLocalizations.of(context).privacyPolicyContent,
    );
  }

  void _showTermsOfService() {
    _showInfoDialog(
      title: AppLocalizations.of(context).termsOfService,
      icon: Icons.gavel,
      content: AppLocalizations.of(context).termsOfServiceContent,
    );
  }

  void _showHelpAndSupport() {
    _showInfoDialog(
      title: AppLocalizations.of(context).helpAndSupport,
      icon: Icons.help_outline,
      content: AppLocalizations.of(context).helpAndSupportContent,
    );
  }

  void _showRateApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).rateApp),
          ],
        ),
        content: Text(AppLocalizations.of(context).rateAppContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.star, size: 16),
            label: Text(AppLocalizations.of(context).rateApp),
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('شكراً لك! سيتوفر التقييم عند نشر التطبيق في المتجر ✓',
                  isSuccess: true);
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(height: 1.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
        ],
      ),
    );
  }

  // ─── Notification permission toggle ──────────────────────────────────────
  Future<void> _onNotificationsToggled(bool value) async {
    if (value) {
      final granted = await FCMService.requestPermission();
      if (!granted && mounted) {
        _showSnack('لم يتم منح إذن الإشعارات. فعّلها من إعدادات الهاتف.', isError: true);
        return;
      }
    } else {
      if (mounted) {
        _showSnack('يمكن إيقاف الإشعارات من إعدادات الهاتف ← التطبيقات ← ديبتي');
      }
    }
    setState(() => _notificationsEnabled = value);
    _saveSettings();
  }

  // ─── Send test local notification ───────────────────────────────────
  Future<void> _sendTestNotification() async {
    setState(() => _testingNotification = true);
    try {
      await FCMService.showTestNotification();
      if (mounted) _showSnack('تم إرسال الإشعار التجريبي ✓', isSuccess: true);
    } catch (e) {
      if (mounted) _showSnack('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _testingNotification = false);
    }
  }

  // ─── Trigger notify-upcoming-due edge function ──────────────────────
  Future<void> _triggerUpcomingReminders() async {
    setState(() => _triggeringReminders = true);
    try {
      final result = await _apiService.notifyUpcomingDue(
        daysBefore: _reminderDaysBefore,
      );
      if (mounted) {
        _showSnack(AppLocalizations.of(context).newNotificationsCreated(result.processed), isSuccess: true);
      }
    } catch (e) {
      if (mounted) _showSnack('خطأ في إرسال الإشعارات: $e', isError: true);
    } finally {
      if (mounted) setState(() => _triggeringReminders = false);
    }
  }

  // ─── Show FCM token dialog ─────────────────────────────────────────
  void _showFcmTokenDialog() {
    final token = _fcmToken ?? 'جاري التحميل...';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).showFcmToken),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(ctx).fcmTokenSubtitle, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(AppLocalizations.of(ctx).copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              Navigator.pop(ctx);
              _showSnack(AppLocalizations.of(ctx).copied, isSuccess: true);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? AppColors.success
            : isError
                ? AppColors.error
                : null,
      ),
    );
  }

  Future<void> _syncData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await _apiService.getStatistics();
      if (mounted) {
        Navigator.pop(context);
        _showSnack('تمت المزامنة بنجاح ✓', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('خطأ في المزامنة: $e', isError: true);
      }
    }
  }

  Future<void> _checkOverdue() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final response = await _apiService.checkOverdueInstallments();
      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          'تم تحديث ${response.newlyOverdue} قسط متأخر',
          isSuccess: response.newlyOverdue == 0,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).logoutLabel),
        content: Text(AppLocalizations.of(context).confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context).logoutLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      debugPrint('Starting logout process...');
      await FCMService.deactivateToken();
      await _apiService.logout();

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('خطأ في تسجيل الخروج: $e', isError: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      }
    }
  }
}
