import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_validator.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/debity_button.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/widgets/debity_logo.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final pwd = _passwordController.text;
    if (!PasswordValidator.isValid(pwd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).password_requirements),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String phone = _phoneController.text.trim();
      phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (phone.startsWith('0')) phone = '+964${phone.substring(1)}';
      if (!phone.startsWith('+')) phone = '+964$phone';

      await AuthService().register(
        email: _emailController.text.trim(),
        password: pwd,
        fullName: _nameController.text.trim(),
        phone: phone,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              email: _emailController.text.trim(),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().replaceAll('Exception: ', '');
      String message;
      if (err.contains('already registered') ||
          err.contains('User already exists') ||
          err.contains('already exists')) {
        message = AppLocalizations.of(context).already_have_account;
      } else if (err.contains('invalid email') || err.contains('Invalid email')) {
        message = '${AppLocalizations.of(context).emailLabel} ${AppLocalizations.of(context).invalidSuffix}';
      } else if (err.contains('password') || err.contains('Password')) {
        message = AppLocalizations.of(context).password_requirements;
      } else if (err.contains('phone')) {
        message = '${AppLocalizations.of(context).phone_label} ${AppLocalizations.of(context).invalidSuffix}';
      } else if (err.contains('network') ||
          err.contains('Connection') ||
          err.contains('SocketException')) {
        message = AppLocalizations.of(context).noInternet;
      } else {
        message = err.isNotEmpty ? err : 'خطأ في التسجيل';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surface0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: DebityLogo(size: LogoSize.lg)),
                const SizedBox(height: 24),
                Text(
                  'إنشاء حساب جديد',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.of(context).textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل بياناتك للبدء',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DebityTextField(
                        controller: _nameController,
                        label: AppLocalizations.of(context).fullName_label,
                        prefixIcon: const Icon(Icons.person_outline),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppLocalizations.of(context).full_name_required
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DebityTextField(
                        controller: _phoneController,
                        label: AppLocalizations.of(context).phone_label,
                        hintText: AppLocalizations.of(context).phone_hint,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return AppLocalizations.of(context).phone_required;
                          }
                          if (v.trim().length < 10) {
                            return AppLocalizations.of(context).phone_too_short;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DebityTextField(
                        controller: _emailController,
                        label: AppLocalizations.of(context).emailLabel,
                        hintText: 'example@mail.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '${AppLocalizations.of(context).emailLabel} ${AppLocalizations.of(context).requiredSuffix}';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return '${AppLocalizations.of(context).emailLabel} ${AppLocalizations.of(context).invalidSuffix}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DebityTextField(
                        controller: _passwordController,
                        label: AppLocalizations.of(context).password_label,
                        hintText: '••••••••',
                        obscureText: _obscurePassword,
                        showPasswordToggle: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _register(),
                        validator: PasswordValidator.validate,
                      ),
                      if (_password.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _PasswordChecklist(password: _password),
                      ],
                      const SizedBox(height: 32),
                      DebityPrimaryButton(
                        label: AppLocalizations.of(context).register_button,
                        onPressed: _register,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).already_have_account,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pushReplacementNamed('/login'),
                            child: Text(
                              AppLocalizations.of(context).sign_in,
                              style: TextStyle(
                                color: AppColors.brand400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  final String password;
  const _PasswordChecklist({required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PasswordValidator.rules
          .map((rule) => _RuleRow(met: rule.check(password), label: rule.label))
          .toList(),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final bool met;
  final String label;
  const _RuleRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 18,
              color: met ? AppColors.success : AppColors.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? AppColors.of(context).textPrimary : AppColors.textMuted,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

