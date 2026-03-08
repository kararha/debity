import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Adaptive color tokens that flip between dark and light variants.
/// Access via [AppColorScheme.of(context)] or the [AppColors.of] shortcut.
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.borderSubtle,
    required this.borderLight,
  });

  final Color surface0;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color borderSubtle;
  final Color borderLight;

  // ── Dark variant ─────────────────────────────────────────────────────
  static const AppColorScheme dark = AppColorScheme(
    surface0:      AppColors.surface0,      // 0xFF0E0F1A
    surface1:      AppColors.surface1,      // 0xFF131420
    surface2:      AppColors.surface2,      // 0xFF181926
    surface3:      AppColors.surface3,      // 0xFF1D1F2E
    textPrimary:   AppColors.textPrimary,   // 0xFFE8E9F4
    textSecondary: AppColors.textSecondary, // 0xFF94A3B8
    textMuted:     AppColors.textMuted,     // 0xFF64748B
    textFaint:     AppColors.textFaint,     // 0xFF475569
    borderSubtle:  AppColors.borderSubtle,  // white/5
    borderLight:   AppColors.borderLight,   // white/10
  );

  // ── Light variant ────────────────────────────────────────────────────
  static const AppColorScheme light = AppColorScheme(
    surface0:      Color(0xFFF3F4FD), // lightest page bg, brand-tinted
    surface1:      Color(0xFFFFFFFF), // card / appBar
    surface2:      Color(0xFFEEEFF9), // input fill
    surface3:      Color(0xFFE2E4F5), // pressed state
    textPrimary:   Color(0xFF1A1B2E), // very dark navy
    textSecondary: Color(0xFF64748B), // slate-500
    textMuted:     Color(0xFF94A3B8), // slate-400
    textFaint:     Color(0xFFCBD5E1), // slate-300
    borderSubtle:  Color(0x1A000000), // black/10
    borderLight:   Color(0x26000000), // black/15
  );

  // ── ThemeExtension protocol ──────────────────────────────────────────
  @override
  AppColorScheme copyWith({
    Color? surface0, Color? surface1, Color? surface2, Color? surface3,
    Color? textPrimary, Color? textSecondary, Color? textMuted, Color? textFaint,
    Color? borderSubtle, Color? borderLight,
  }) => AppColorScheme(
    surface0:      surface0      ?? this.surface0,
    surface1:      surface1      ?? this.surface1,
    surface2:      surface2      ?? this.surface2,
    surface3:      surface3      ?? this.surface3,
    textPrimary:   textPrimary   ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted:     textMuted     ?? this.textMuted,
    textFaint:     textFaint     ?? this.textFaint,
    borderSubtle:  borderSubtle  ?? this.borderSubtle,
    borderLight:   borderLight   ?? this.borderLight,
  );

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      surface0:      Color.lerp(surface0,      other.surface0,      t)!,
      surface1:      Color.lerp(surface1,      other.surface1,      t)!,
      surface2:      Color.lerp(surface2,      other.surface2,      t)!,
      surface3:      Color.lerp(surface3,      other.surface3,      t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted,     other.textMuted,     t)!,
      textFaint:     Color.lerp(textFaint,     other.textFaint,     t)!,
      borderSubtle:  Color.lerp(borderSubtle,  other.borderSubtle,  t)!,
      borderLight:   Color.lerp(borderLight,   other.borderLight,   t)!,
    );
  }

  /// Lookup from context. Falls back to dark if the extension is missing.
  static AppColorScheme of(BuildContext context) =>
      Theme.of(context).extension<AppColorScheme>() ?? dark;
}
