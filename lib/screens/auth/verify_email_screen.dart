import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

import '../auth/auth_screen.dart';

/// Shown immediately after successful registration.
/// The user CANNOT log in from this screen — they must click the email link first.
class VerifyEmailScreen extends StatelessWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primaryColor],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(top: -80, right: -50, child: _glowCircle(200, 0.06)),
            Positioned(bottom: -90, left: -60, child: _glowCircle(250, 0.05)),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // ── Icon ────────────────────────────────────────────────
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(255, 255, 255, 0.12),
                        border: Border.all(
                          color: Color.fromRGBO(255, 255, 255, 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Glass card ───────────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Color.fromRGBO(255, 255, 255, 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context).verifyEmailTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppLocalizations.of(context).verifyEmailSentTo,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromRGBO(255, 255, 255, 0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 20),

                              // Steps
                              _step(
                                icon: Icons.email_outlined,
                                text: AppLocalizations.of(context).openConfirmationEmail,
                              ),
                              const SizedBox(height: 12),
                              _step(
                                icon: Icons.touch_app_outlined,
                                text: AppLocalizations.of(context).clickActivationLink,
                              ),
                              const SizedBox(height: 12),
                              _step(
                                icon: Icons.login_outlined,
                                text: AppLocalizations.of(context).returnToAppAndLogin,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // ── Go-to-login button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context).goToLogin,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note
                    Text(
                      AppLocalizations.of(context).checkSpamNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Color.fromRGBO(255, 255, 255, 0.5),
                          height: 1.5,
                        ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _glowCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(255, 255, 255, opacity),
          ),
    );
  }
}
