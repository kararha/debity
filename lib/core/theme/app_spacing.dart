/// Debity design-system spacing tokens.
/// All values use a base-4dp scale.
class AppSpacing {
  AppSpacing._();

  // Base scale
  static const double sp2  = 2;
  static const double sp4  = 4;
  static const double sp6  = 6;
  static const double sp8  = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp28 = 28;
  static const double sp32 = 32;
  static const double sp40 = 40;
  static const double sp48 = 48;
  static const double sp64 = 64;

  // Semantic aliases
  /// Horizontal page padding (mobile)
  static const double pageH = 16;
  /// Top page padding
  static const double pageT = 32;
  /// Vertical gap between sections
  static const double sectionGap = 24;
  /// Stat card inner padding
  static const double statCardPad = 20;
  /// Panel card inner padding
  static const double panelPad = 24;
  /// List item vertical padding
  static const double listItemV = 12;
  /// List item horizontal padding
  static const double listItemH = 12;
  /// Gap between list items
  static const double listGap = 8;
  /// Bottom nav height (without safe area)
  static const double bottomNavH = 64;
  /// App bar height
  static const double appBarH = 64;
}

/// Border radius tokens.
class AppRadius {
  AppRadius._();

  /// Badges, scrollbar thumb, small chips
  static const double sm = 6;
  /// Input fields, nav items, small cards
  static const double md = 8;
  /// Main cards, panels
  static const double lg = 12;
  /// Large cards, auth card, logo container sm
  static const double xl = 16;
  /// Auth card
  static const double xxl = 20;
  /// Pill (fully rounded)
  static const double pill = 999;
}
