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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.openLoginSheetOnLoad = false});

  final bool openLoginSheetOnLoad;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<_AuthBottomSheetState> _sheetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.openLoginSheetOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sheetKey.currentState?.open();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surface0,
      body: Stack(
        children: [
          SafeArea(
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
                      const DebityLogo(size: LogoSize.lg),
                      const SizedBox(height: AppSpacing.sp48),
                      Text(
                        AppLocalizations.of(context).tagline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.base.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp48),
                      _LanguageToggle(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _AuthBottomSheet(key: _sheetKey),
        ],
      ),
    );
  }
}

class _AuthBottomSheet extends StatefulWidget {
  const _AuthBottomSheet({Key? key}) : super(key: key);

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet> {
  bool _isLogin = true;
  int _currentPage = 0;

  void open() {
    setState(() => _currentPage = 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -200) {
                setState(() => _currentPage = 1);
              } else if (details.primaryVelocity! > 200) {
                setState(() => _currentPage = 0);
              }
            },
            onTap: () {
              if (_currentPage == 0) {
                setState(() => _currentPage = 1);
              }
            },
            child: Container(
              height: _currentPage == 0 ? 80 : constraints.maxHeight * 0.85,
              decoration: BoxDecoration(
                color: AppColors.of(context).surface1,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_currentPage == 0 ? 20 : AppRadius.xxl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _currentPage == 0 ? _buildCollapsed() : _buildExpanded(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsed() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.of(context).borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
            style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'ليس لديك حساب؟' : 'لديك حساب بالفعل؟',
                style: AppTextStyles.xs.copyWith(color: AppColors.textMuted),
              ),
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'إنشاء حساب' : 'تسجيل الدخول',
                  style: AppTextStyles.xs.copyWith(
                    color: AppColors.brand400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sp24,
            AppSpacing.sp16,
            AppSpacing.sp24,
            AppSpacing.sp40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentPage = 0),
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TabButton(
                    label: 'تسجيل الدخول',
                    isSelected: _isLogin,
                    onTap: () => setState(() => _isLogin = true),
                  ),
                  const SizedBox(width: 16),
                  _TabButton(
                    label: 'إنشاء حساب',
                    isSelected: !_isLogin,
                    onTap: () => setState(() => _isLogin = false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp24),
              _isLogin ? const _LoginForm() : const _RegisterForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand500 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.sm.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
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
          border: Border.all(
            color: AppColors.of(context).borderLight,
            width: 1,
          ),
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

// ═══════════════════════════════════════════════════════════════════════
// LOGIN FORM
// ═══════════════════════════════════════════════════════════════════════

class _LoginForm extends StatefulWidget {
  const _LoginForm();
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
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
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

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
      if (mounted)
        setState(() {
          _errorMsg = _parseError(e.toString());
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'تسجيل الدخول',
            style: AppTextStyles.xl.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            'سجّل دخولك للمتابعة',
            style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sp24),

          if (_errorMsg != null)
            ErrorBanner(
              message: _errorMsg!,
              onDismiss: () => setState(() => _errorMsg = null),
            ),

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
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// REGISTER FORM
// ═══════════════════════════════════════════════════════════════════════

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
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
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

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
      if (mounted)
        setState(() {
          _errorMsg = _parseError(e.toString());
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'إنشاء حساب جديد',
            style: AppTextStyles.xl.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            'أدخل بياناتك للبدء',
            style: AppTextStyles.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sp24),

          if (_errorMsg != null)
            ErrorBanner(
              message: _errorMsg!,
              onDismiss: () => setState(() => _errorMsg = null),
            ),

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
              if (v == null || v.trim().isEmpty)
                return 'الرجاء إدخال رقم الهاتف';
              if (v.trim().length < 10)
                return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
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
        ],
      ),
    );
  }
}

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
