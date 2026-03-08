import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../l10n/app_localizations.dart';

/// Size variants for the Debity logo.
enum LogoSize { sm, md, lg }

/// Debity brand logo — geometric "D" icon + "Debi**ty**" wordmark.
///
/// Follows the design spec exactly:
///  - Icon: brand-500 rounded-square container, white SVG "D" mark + accent circle
///  - Wordmark: "Debi" in brand-400, "ty" in white
class DebityLogo extends StatelessWidget {
  const DebityLogo({
    super.key,
    this.size = LogoSize.md,
    this.showWordmark = true,
  });

  final LogoSize size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final containerSize = _containerSize;
    final radius = _radius;
    final gap = _gap;
    final fontSize = _fontSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Icon container ──────────────────────────────────────────
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: AppColors.brand500,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO((AppColors.brand500.toARGB32() >> 16) & 0xFF, (AppColors.brand500.toARGB32() >> 8) & 0xFF, AppColors.brand500.toARGB32() & 0xFF, 0.20),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _DIconPainter(containerSize: containerSize),
          ),
        ),

        if (showWordmark) ...[
          SizedBox(width: gap),
          // ── Wordmark (localized) ─────────────────────────────────
          Builder(builder: (ctx) {
            final loc = AppLocalizations.of(ctx);
            // For English keep the branded split wordmark, otherwise render localized app name.
            if (loc.locale.languageCode == 'en') {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Debi',
                      style: AppTextStyles.xl2.copyWith(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand400,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'ty',
                      style: AppTextStyles.xl2.copyWith(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(ctx).textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Text(
              loc.appName,
              style: AppTextStyles.xl2.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.of(ctx).textPrimary,
                letterSpacing: -0.5,
              ),
            );
          }),
        ],
      ],
    );
  }

  double get _containerSize => switch (size) {
        LogoSize.sm => 32,
        LogoSize.md => 48,
        LogoSize.lg => 64,
      };

  double get _radius => switch (size) {
        LogoSize.sm => AppRadius.md,
        LogoSize.md => AppRadius.lg,
        LogoSize.lg => AppRadius.xl,
      };

  double get _gap => switch (size) {
        LogoSize.sm => 10,
        LogoSize.md => 12,
        LogoSize.lg => 16,
      };

  double get _fontSize => switch (size) {
        LogoSize.sm => 18,
        LogoSize.md => 24,
        LogoSize.lg => 30,
      };
}

/// Paints the geometric D mark inside the icon container.
///
/// ViewBox: 64×64, scaled to fit [containerSize].
class _DIconPainter extends CustomPainter {
  const _DIconPainter({required this.containerSize});
  final double containerSize;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Vertical line: x=18, y1=14, y2=50
    canvas.drawLine(const Offset(18, 14), const Offset(18, 50), strokePaint);

    // Outer D arc
    final path = Path()
      ..moveTo(18, 14)
      ..lineTo(28, 14)
      ..cubicTo(43, 14, 50, 22, 50, 32)
      ..cubicTo(50, 42, 43, 50, 28, 50)
      ..lineTo(18, 50);
    canvas.drawPath(path, strokePaint);

    // Accent circle: center(32,32), r=4, fill white/40%
    final accentPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 32), 4, accentPaint);
  }

  @override
  bool shouldRepaint(_DIconPainter old) => old.containerSize != containerSize;
}
