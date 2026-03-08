import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Debity design-system typography.
///
/// Primary font  : Inter (LTR)
/// Arabic font   : Noto Sans Arabic (RTL)
/// Monospace     : JetBrains Mono (numeric amounts)
class AppTextStyles {
  AppTextStyles._();

  // ─── Helper: pick font family based on locale ──────────────────────
  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color? color,   // null → inherits theme onSurface
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height ?? 1.6,
      );

  static TextStyle _notoArabic({
    required double size,
    required FontWeight weight,
    Color? color,   // null → inherits theme onSurface
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.notoSansArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height ?? 1.6,
      );

  /// Return [arabic] style when [isRtl] is true, otherwise [ltr] style.
  static TextStyle resolve(
    TextStyle ltr,
    TextStyle arabic, {
    required bool isRtl,
  }) =>
      isRtl ? arabic : ltr;

  // ─── Scale (LTR / Inter) ────────────────────────────────────────────

  // xs — 11px w400
  static final TextStyle xs = _inter(size: 11, weight: FontWeight.w400, color: AppColors.textSecondary);
  // sm — 13px w400
  static final TextStyle sm = _inter(size: 13, weight: FontWeight.w400);
  // base — 14px w400
  static final TextStyle base = _inter(size: 14, weight: FontWeight.w400);
  // md — 16px w500
  static final TextStyle md = _inter(size: 16, weight: FontWeight.w500);
  // lg — 18px w600
  static final TextStyle lg = _inter(size: 18, weight: FontWeight.w600);
  // xl — 20px w700
  static final TextStyle xl = _inter(size: 20, weight: FontWeight.w700);
  // 2xl — 24px w700 letterSpacing -0.5
  static final TextStyle xl2 = _inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.5);
  // 3xl — 30px w700 (auth wordmark)
  static final TextStyle xl3 = _inter(size: 30, weight: FontWeight.w700, letterSpacing: -0.5);
  // 4xl — 36px w700 (splash logo)
  static final TextStyle xl4 = _inter(size: 36, weight: FontWeight.w700, letterSpacing: -0.5);

  // ─── Scale (RTL / Noto Sans Arabic) ────────────────────────────────
  static final TextStyle xsAr   = _notoArabic(size: 11, weight: FontWeight.w400, color: AppColors.textSecondary);
  static final TextStyle smAr   = _notoArabic(size: 13, weight: FontWeight.w400);
  static final TextStyle baseAr = _notoArabic(size: 14, weight: FontWeight.w400);
  static final TextStyle mdAr   = _notoArabic(size: 16, weight: FontWeight.w500);
  static final TextStyle lgAr   = _notoArabic(size: 18, weight: FontWeight.w600);
  static final TextStyle xlAr   = _notoArabic(size: 20, weight: FontWeight.w700);
  static final TextStyle xl2Ar  = _notoArabic(size: 24, weight: FontWeight.w700);
  static final TextStyle xl3Ar  = _notoArabic(size: 30, weight: FontWeight.w700);
  static final TextStyle xl4Ar  = _notoArabic(size: 36, weight: FontWeight.w700);

  // ─── Semantic helpers ───────────────────────────────────────────────
  static TextStyle get statLabel => xs.copyWith(
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get statValue => xl2;
  static TextStyle get sectionTitle => md.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get listPrimary => base.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get listSecondary => xs.copyWith(fontSize: 12, color: AppColors.textSecondary);
  static TextStyle get listAmount => base.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get listDate => xs.copyWith(fontSize: 12, color: AppColors.textMuted);
  static TextStyle get inputLabel => base.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle get inputText => base;
  static TextStyle get inputHint => base.copyWith(color: AppColors.textMuted);
  static TextStyle get btnPrimary => _inter(size: 15, weight: FontWeight.w600, color: Colors.white);
  static TextStyle get navLabel => xs.copyWith(fontSize: 11, fontWeight: FontWeight.w500);
  static TextStyle get badgeText => xs.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2);

  // ─── TextTheme (used in ThemeData) ──────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge:  xl4,
        displayMedium: xl3,
        displaySmall:  xl2,
        headlineLarge: xl,
        headlineMedium: lg,
        headlineSmall:  md,
        titleLarge:    lg,
        titleMedium:   md,
        titleSmall:    sm,
        bodyLarge:     md,
        bodyMedium:    base,
        bodySmall:     sm,
        labelLarge:    base.copyWith(fontWeight: FontWeight.w600),
        labelMedium:   sm.copyWith(fontWeight: FontWeight.w500),
        labelSmall:    xs,
      );

  // ─── Backward-compat aliases ----------------------------------------
  static TextStyle get headline1 => xl4;
  static TextStyle get headline2 => xl2;
  static TextStyle get headline3 => xl;
  static TextStyle get headline4 => lg;
  static TextStyle get bodyLarge => md;
  static TextStyle get bodyMedium => base;
  static TextStyle get bodySmall => sm;
  static TextStyle get labelLarge => base.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get labelMedium => sm.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get button => btnPrimary;
  static TextStyle get caption => xs;
}
