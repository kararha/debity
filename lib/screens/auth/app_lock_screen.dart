import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:secure_application/secure_application.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Start authentication automatically when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'يرجى المصادقة للوصول إلى بياناتك المالية',
          biometricOnly: false,
          persistAcrossBackgrounding: true,
        );

        if (didAuthenticate && mounted) {
          SecureApplicationProvider.of(context)?.unlock();
        }
      } else {
        // If biometrics are not supported on the device, unlock automatically
        // to prevent trapping the user on the lock screen.
        if (mounted) {
          SecureApplicationProvider.of(context)?.unlock();
        }
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.surface0,
      body: Stack(
        children: [
          // Background mesh circles for premium visual polish
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand500.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Main UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sp24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon / Logo container
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sp24),
                      decoration: BoxDecoration(
                        color: c.surface1.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.borderSubtle,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 64,
                        color: AppColors.brand500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp32),
                    
                    // App Name
                    const Text(
                      'ديبتي',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand500, // Keep brand color signature on logo
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp12),
                    
                    // Description text
                    Text(
                      'التطبيق مقفل لحماية بياناتك المالية والائتمانية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: c.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp48),
                    
                    // Unlock button or Loading indicator
                    if (_isAuthenticating)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand500),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _authenticate,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('إلغاء قفل التطبيق'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand500,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp32,
                            vertical: AppSpacing.sp16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}