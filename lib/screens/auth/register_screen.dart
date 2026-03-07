import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_validator.dart';
import '../../core/l10n/app_localizations.dart';
import 'auth_screen.dart';
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

  // --- Registration logic (UNCHANGED) ---

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

      // Spec: after success → show "Check your email" screen. Do NOT log in.
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

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      resizeToAvoidBottomInset: true, // Crucial for the bottom sheet layout
      body: Stack(
        children: [
          // 1. Vibrant Background
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

          // 2. Decorative Blurred Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _blob(AppColors.primaryColor.withOpacity(0.4), 300),
          ),
          Positioned(
            top: 150,
            left: -50,
            child: _blob(AppColors.secondaryColor.withOpacity(0.4), 200),
          ),

          // 3. Main Scrollable Layout
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // --- TOP HALF: Welcome Info ---
                        Expanded(
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                    ),
                                    child: const Icon(
                                      Icons.person_add_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppLocalizations.of(context).register_title,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context).register_subtitle,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // --- BOTTOM HALF: The "Drawer" ---
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.surface0,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Drag Handle Pill
                                Container(
                                  width: 48,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.borderSubtle,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Full name
                                _field(
                                  controller: _nameController,
                                  label: AppLocalizations.of(context).fullName_label,
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.trim().isEmpty)
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
                                      return '${AppLocalizations.of(context).emailLabel} ${AppLocalizations.of(context).requiredSuffix}';
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return '${AppLocalizations.of(context).emailLabel} ${AppLocalizations.of(context).invalidSuffix}';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context).password_label,
                                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                                    filled: true,
                                    fillColor: AppColors.surface1,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.brand500, width: 2),
                                    ),
                                    errorStyle: const TextStyle(color: AppColors.error),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: PasswordValidator.validate,
                                ),

                                // Live password checklist
                                if (_password.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _PasswordChecklist(password: _password),
                                ],

                                const SizedBox(height: 32),

                                // Register button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brand500,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
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
                                          : () => AuthScreen.showLoginSheet(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.brand500,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context).sign_in,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

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
      style: const TextStyle(color: AppColors.textPrimary), // Updated for surface
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface1, // Updated for surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brand500, width: 2),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
      validator: validator,
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

// --- Live password checklist widget ---

/// Shows four rule rows with animated ✓ / ○ indicators.
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
              color: met ? AppColors.success : AppColors.textMuted.withOpacity(0.5), // Updated colors
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? AppColors.textPrimary : AppColors.textMuted, // Updated colors
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}