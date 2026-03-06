import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_validator.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/l10n/app_localizations.dart';
import 'login_screen.dart';
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
      setState(() => _password = _passwordController.text);
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

  // â”€â”€ Registration logic â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra guard: make sure all 4 password conditions are met before sending.
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

    setState(() => _isLoading = true);

    try {
      // Normalise Iraqi phone number to E.164
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

      // Spec: after success â†’ show "Check your email" screen. Do NOT log in.
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
        message = AppLocalizations.of(context).emailLabel + ' غير صحيحة';
      } else if (err.contains('password') || err.contains('Password')) {
        message = AppLocalizations.of(context).password_requirements;
      } else if (err.contains('phone')) {
        message = AppLocalizations.of(context).phone_label + ' غير صحيح';
      } else if (err.contains('network') ||
          err.contains('Connection') ||
          err.contains('SocketException')) {
        message = AppLocalizations.of(context).noInternet + ' — تحقق من الإنترنت';
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

  // â”€â”€ UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),

          // Decorative blobs
          Positioned(
            top: -100,
            right: -100,
            child: _blob(AppColors.primaryColor.withOpacity(0.4), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blob(AppColors.secondaryColor.withOpacity(0.4), 200),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).register_title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).register_subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 32),

                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full name
                            _field(
                              controller: _nameController,
                              label: AppLocalizations.of(context).fullName_label,
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? AppLocalizations.of(context).full_name_required
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            // Phone
                            _field(
                              controller: _phoneController,
                              label: AppLocalizations.of(context).phone_label,
                              icon: Icons.phone_outlined,
                              hint: AppLocalizations.of(context).phone_hint,
                              keyboardType: TextInputType.phone,
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

                            // Email
                            _field(
                              controller: _emailController,
                              label: AppLocalizations.of(context).emailLabel,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return AppLocalizations.of(context).emailLabel + ' مطلوب';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return AppLocalizations.of(context).emailLabel + ' غير صحيحة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: AppLocalizations.of(context).password_label,
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: PasswordValidator.validate,
                            ),

                            // â”€â”€ Live password checklist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                            if (_password.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _PasswordChecklist(password: _password),
                            ],

                            const SizedBox(height: 24),

                            // Register button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context).register_button,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).already_have_account,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context)
                                    .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                ),
                            child: Text(AppLocalizations.of(context).sign_in),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label: label, icon: icon, hint: hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// â”€â”€ Live password checklist widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Shows four rule rows with animated âœ“ / â—‹ indicators.
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
              color: met ? AppColors.success : Colors.white38,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? Colors.white70 : Colors.white38,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

