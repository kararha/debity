import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme controller — exposes a [ValueNotifier] so any widget can
/// listen and rebuild when the user switches light / dark / system mode.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  /// Call this once in main() before runApp — loads the persisted choice.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    themeMode.value = ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
  }

  /// Change and persist the theme mode.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}
