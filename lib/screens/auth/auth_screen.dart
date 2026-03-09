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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() => _isLogin = _tabController!.index == 0);
      }
    });
    if (widget.openLoginSheetOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController?.animateTo(1);
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surface0,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageH,
                  vertical: AppSpacing.sp48,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const DebityLogo(size: LogoSize.lg),
                      const SizedBox(height: AppSpacing.sp24),
                      Text(
                        AppLocalizations.of(context).tagline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.base.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      _buildLanguageToggle(),
                    ],
                  ),
                ),
              ),
            ),
            _buildAuthCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.of(context).borderLight,
          width: 1,
        ),
      ),
      child: Text(
        'AR  |  EN',
        style: AppTextStyles.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border.all(
          color: AppColors.of(context).borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp24,
              AppSpacing.sp16,
              AppSpacing.sp24,
              AppSpacing.sp32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildTabBar(),
                const SizedBox(height: AppSpacing.sp24),
                _isLogin ? const _LoginForm() : const _RegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController!,
        indicator: BoxDecoration(
          color: AppColors.brand500,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.sm.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.sm,
        tabs: const [
          Tab(text: 'تسجيل الدخول'),
          Tab(text: 'إنشاء حساب'),
        ],
      ),
    );
  }
}

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
          if (_errorMsg != null) ...[
            ErrorBanner(
              message: _errorMsg!,
              onDismiss: () => setState(() => _errorMsg = null),
            ),
            const SizedBox(height: AppSpacing.sp16),
          ],
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
          const SizedBox(height: AppSpacing.sp8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'نسيت كلمة المرور؟',
                style: AppTextStyles.sm.copyWith(
                  color: AppColors.brand400,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
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
          if (_errorMsg != null) ...[
            ErrorBanner(
              message: _errorMsg!,
              onDismiss: () => setState(() => _errorMsg = null),
            ),
            const SizedBox(height: AppSpacing.sp16),
          ],
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
