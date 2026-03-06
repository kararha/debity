import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/auth_service.dart';
import '../core/theme/app_colors.dart';
import 'auth/auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _contentController;
  late final AnimationController _shimmerController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // --- Logo animation (0 → 800ms) ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // --- Staggered content ---
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
          ),
        );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeIn),
      ),
    );
    _loaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    // --- Shimmer spinner loop ---
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Kick off sequence
    _logoController.forward().then((_) => _contentController.forward());
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Try to restore session from stored refresh_token (via AuthService).
    // This calls the refresh-token edge function and hydrates the Supabase client.
    final restored = await AuthService().tryRestoreSession();
    final next = restored ? const HomeScreen() : const AuthScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primaryColor],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glow circles
            Positioned(top: -80, right: -60, child: _glowCircle(220, 0.07)),
            Positioned(bottom: -100, left: -70, child: _glowCircle(280, 0.05)),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: -40,
              child: _glowCircle(140, 0.06),
            ),

            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Logo ---
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) => Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      ),
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // --- App name ---
                    AnimatedBuilder(
                      animation: _contentController,
                      builder: (context, child) => SlideTransition(
                        position: _titleSlide,
                        child: Opacity(opacity: _titleFade.value, child: child),
                      ),
                      child: Text(
                        AppLocalizations.of(context).appName,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Color(0x40000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- Tagline ---
                    AnimatedBuilder(
                      animation: _contentController,
                      builder: (context, child) => SlideTransition(
                        position: _taglineSlide,
                        child: Opacity(
                          opacity: _taglineFade.value,
                          child: child,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).tagline,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),

                    // --- Custom arc loader ---
                    AnimatedBuilder(
                      animation: _contentController,
                      builder: (context, child) =>
                          Opacity(opacity: _loaderFade.value, child: child),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) => Transform.rotate(
                            angle: _shimmerController.value * 6.283,
                            child: CustomPaint(
                              painter: _ArcPainter(
                                color: Colors.white.withOpacity(0.85),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Version label
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) =>
                    Opacity(opacity: _loaderFade.value, child: child),
                child: Text(
                  AppLocalizations.of(context).versionLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      4.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
