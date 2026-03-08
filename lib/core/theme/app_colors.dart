import 'package:flutter/material.dart';
import 'app_color_scheme.dart';

/// Debity design-system color tokens.
///
/// Brand / semantic colors are mode-independent.
/// Surface / text / border tokens are adaptive — use [AppColors.of(context)]
/// which returns an [AppColorScheme] for the current [ThemeMode].
class AppColors {
  AppColors._();

  /// Returns the adaptive color tokens for the current theme mode.
  /// Use this instead of the raw surface/text/border constants.
  static AppColorScheme of(BuildContext context) =>
      AppColorScheme.of(context);

  // ─── Brand palette (blue-indigo ~250°) ─────────────────────────────
  static const Color brand50  = Color(0xFFF2F3FF);
  static const Color brand100 = Color(0xFFE8EAF9);
  static const Color brand200 = Color(0xFFD4D8F4);
  static const Color brand300 = Color(0xFFB4BCEA);
  /// Active nav icon / accent text
  static const Color brand400 = Color(0xFF8B9EDD);
  /// Logo background / primary button fill
  static const Color brand500 = Color(0xFF6271C4);
  static const Color brand600 = Color(0xFF4F5DAB);
  /// Scrollbar thumb
  static const Color brand700 = Color(0xFF404D8F);
  static const Color brand800 = Color(0xFF333D74);
  static const Color brand900 = Color(0xFF293060);
  static const Color brand950 = Color(0xFF1E234A);

  // ─── Surface layers (dark blue-black) ──────────────────────────────
  /// Scaffold / page background
  static const Color surface0 = Color(0xFF0E0F1A);
  /// Card background, bottom nav, header
  static const Color surface1 = Color(0xFF131420);
  /// Input fields, list item background
  static const Color surface2 = Color(0xFF181926);
  /// List item hover / pressed state
  static const Color surface3 = Color(0xFF1D1F2E);

  // ─── Semantic ───────────────────────────────────────────────────────
  /// Emerald-400 — paid status
  static const Color success = Color(0xFF34D399);
  /// Amber-400 — partial / remaining
  static const Color warning = Color(0xFFFBBF24);
  /// Red-400 — overdue status
  static const Color danger  = Color(0xFFF87171);
  /// Brand-400 text (e.g. "Debi" in logo)
  static const Color brand   = Color(0xFF818CF8);

  // Aliases kept for backward compat with existing screens
  static const Color primaryColor   = brand500;
  static const Color primaryDark    = brand700;
  static const Color primaryLight   = brand200;
  static const Color secondaryColor = success;
  static const Color accentColor    = warning;
  static const Color error          = danger;
  static const Color paidColor      = success;
  static const Color pendingColor   = warning;
  static const Color overdueColor   = danger;
  static const Color partialColor   = warning;
  static const Color info           = brand400;

  // ─── Text ───────────────────────────────────────────────────────────
  /// Near-white body text
  static const Color textPrimary   = Color(0xFFE8E9F4);
  /// Slate-400 labels / subtitles
  static const Color textSecondary = Color(0xFF94A3B8);
  /// Slate-500 timestamps / hints
  static const Color textMuted     = Color(0xFF64748B);
  /// Slate-600 version text
  static const Color textFaint     = Color(0xFF475569);
  static const Color textHint      = textMuted;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Borders ────────────────────────────────────────────────────────
  /// White/5 — card borders
  static const Color borderSubtle = Color(0x0DFFFFFF);
  /// White/10 — input borders
  static const Color borderLight  = Color(0x1AFFFFFF);

  // ─── Legacy aliases (for screens not yet migrated) ──────────────────
  static const Color backgroundColor    = surface0;
  static const Color surfaceColor       = surface1;
  static const Color cardColor          = surface1;
  static const Color borderColor        = borderSubtle;
  static const Color dividerColor       = borderLight;
  static const Color shadowColor        = Color(0xFF000000);
  static const Color darkBackground     = surface0;
  static const Color darkSurface        = surface1;
  static const Color darkCard           = surface2;
  static const Color darkTextPrimary    = textPrimary;
  static const Color darkTextSecondary  = textSecondary;
}
