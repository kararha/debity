import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/password_validator.dart';
import '../../core/widgets/debity_button.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/widgets/debity_logo.dart';
import '../../core/widgets/error_banner.dart';
import '../home_screen.dart';
import 'verify_email_screen.dart';

/// Debity auth landing screen — dark mode, centered design.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.openLoginSheetOnLoad = false});

  final bool openLoginSheetOnLoad;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openLoginSheetOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _AuthScreenState._showLoginSheet(context);
      });
    }
  }

  static void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LoginSheet(),
    );
  }

  static void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RegisterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surface0,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.pageH,
              right: AppSpacing.pageH,
              top: AppSpacing.sp48,
              bottom: AppSpacing.sp8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ─────────────────────────────────────────
                  const DebityLogo(size: LogoSize.lg),
                  const SizedBox(height: AppSpacing.sp48),

                  // ── Subtitle ─────────────────────────────────────
                  Text(
                    AppLocalizations.of(context).tagline,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.base.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp48),

                  // ── Language toggle ───────────────────────────────
                  _LanguageToggle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom sheets ─────────────────────────────────────────────────
}

// ═══════════════════════════════════════════════════════════════════════
// Language toggle pill
// ═══════════════════════════════════════════════════════════════════════

class _LanguageToggle extends StatefulWidget {
  @override
  State<_LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<_LanguageToggle> {
  bool _isArabic = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isArabic = !_isArabic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.of(context).borderLight, width: 1),
        ),
        child: Text(
          _isArabic ? 'AR  |  EN' : 'EN  |  AR',
          style: AppTextStyles.xs.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Embedded login form removed — use bottom-sheet variants instead.

// ═══════════════════════════════════════════════════════════════════════
// LOGIN SHEET (bottom-sheet variant for quick access)
// ═══════════════════════════════════════════════════════════════════════

class _LoginSheet extends StatefulWidget {
  const _LoginSheet();
  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      await AuthService().login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() { _errorMsg = _parseError(e.toString()); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return _SheetWrapper(
      bottomInset: bottomInset,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تسجيل الدخول',
                style: AppTextStyles.xl.copyWith(color: AppColors.of(context).textPrimary)),
            const SizedBox(height: AppSpacing.sp4),
            Text('سجّل دخولك للمتابعة',
                style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sp24),

            if (_errorMsg != null)
              ErrorBanner(
                  message: _errorMsg!,
                  onDismiss: () => setState(() => _errorMsg = null)),

            DebityTextField(
              controller: _emailCtrl,
              label: 'البريد الإلكتروني',
              hintText: 'example@mail.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: _emailValidator,
            ),
            const SizedBox(height: AppSpacing.sp16),
            DebityTextField(
              controller: _passwordCtrl,
              label: 'كلمة المرور',
              hintText: '••••••••',
              obscureText: true,
              showPasswordToggle: true,
              prefixIcon: const Icon(Icons.lock_outline),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'الرجاء إدخال كلمة المرور' : null,
            ),
            const SizedBox(height: AppSpacing.sp24),

            DebityPrimaryButton(
              label: 'تسجيل الدخول',
              onPressed: _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: AppSpacing.sp12),

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _AuthScreenState._showRegisterSheet(context);
                },
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'ليس لديك حساب؟  ',
                      style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'إنشاء حساب',
                      style: AppTextStyles.sm.copyWith(
                        color: AppColors.brand400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// REGISTER SHEET
// ═══════════════════════════════════════════════════════════════════════

class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet();
  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      String phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
      if (phone.startsWith('0')) {
        phone = '+964${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        phone = '+964$phone';
      }

      await AuthService().register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        phone: phone,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: _emailCtrl.text.trim()),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() { _errorMsg = _parseError(e.toString()); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return _SheetWrapper(
      bottomInset: bottomInset,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إنشاء حساب جديد',
                style: AppTextStyles.xl.copyWith(color: AppColors.of(context).textPrimary)),
            const SizedBox(height: AppSpacing.sp4),
            Text('أدخل بياناتك للبدء',
                style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sp24),

            if (_errorMsg != null)
              ErrorBanner(
                  message: _errorMsg!,
                  onDismiss: () => setState(() => _errorMsg = null)),

            DebityTextField(
              controller: _nameCtrl,
              label: 'الاسم الكامل',
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم' : null,
            ),
            const SizedBox(height: AppSpacing.sp16),
            DebityTextField(
              controller: _phoneCtrl,
              label: 'رقم الهاتف',
              hintText: '07xxxxxxxxx',
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الرجاء إدخال رقم الهاتف';
                if (v.trim().length < 10) return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sp16),
            DebityTextField(
              controller: _emailCtrl,
              label: 'البريد الإلكتروني',
              hintText: 'example@mail.com',
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _emailValidator,
            ),
            const SizedBox(height: AppSpacing.sp16),
            DebityTextField(
              controller: _passwordCtrl,
              label: 'كلمة المرور',
              hintText: '••••••••',
              obscureText: true,
              showPasswordToggle: true,
              prefixIcon: const Icon(Icons.lock_outline),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: PasswordValidator.validate,
            ),
            const SizedBox(height: AppSpacing.sp24),

            DebityPrimaryButton(
              label: 'إنشاء حساب',
              onPressed: _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: AppSpacing.sp12),

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _AuthScreenState._showLoginSheet(context);
                },
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'لديك حساب بالفعل؟  ',
                      style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'تسجيل الدخول',
                      style: AppTextStyles.sm.copyWith(
                        color: AppColors.brand400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SheetWrapper extends StatelessWidget {
  const _SheetWrapper({required this.bottomInset, required this.child});
  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sp24, AppSpacing.sp16,
            AppSpacing.sp24, AppSpacing.sp20 + bottomInset,
          ),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
            border: Border(
              top: BorderSide(color: AppColors.of(context).borderSubtle, width: 1),
            ),
          ),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}

Widget _sheetHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────

String? _emailValidator(String? v) {
  if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
  if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
  return null;
}

String _parseError(String raw) {
  final s = raw.replaceAll('Exception: ', '');
  if (s.contains('Invalid login credentials') ||
      s.contains('invalid credentials') ||
      s.contains('invalid_grant')) {
    return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
  }
  if (s.contains('Email not confirmed') || s.contains('email_not_confirmed')) {
    return 'يجب تأكيد البريد الإلكتروني أولاً — تحقق من صندوق الوارد';
  }
  if (s.contains('User not found') || s.contains('user_not_found')) {
    return 'الحساب غير موجود';
  }
  if (s.contains('already registered') ||
      s.contains('User already exists') ||
      s.contains('already exists')) {
    return 'هذا البريد الإلكتروني مسجل بالفعل';
  }
  if (s.contains('password') || s.contains('Password')) {
    return 'كلمة المرور لا تستوفي الشروط';
  }
  if (s.contains('phone')) return 'رقم الهاتف غير صحيح';
  if (s.contains('network') ||
      s.contains('Connection') ||
      s.contains('SocketException')) {
    return 'خطأ في الاتصال — تحقق من الإنترنت';
  }
  return s.isNotEmpty ? s : 'حدث خطأ غير متوقع';
}
