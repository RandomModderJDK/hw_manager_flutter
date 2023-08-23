import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkThemePreference {
  static const themeStatus = "THEMESTATUS";

  /// 0 - Automatic (System)
  /// 1 - Light
  /// 2 - Dark
  setThemeMode(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(themeStatus, mode.name);
  }

  Future<ThemeMode> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String mName = (prefs.getString(themeStatus) ?? "system");
    ThemeMode mode = ThemeMode.values.firstWhere((m) => m.name == mName);
    return mode;
  }

  Future<ThemeMode> nextThemeMode() async {
    switch (await getThemeMode()) {
      case ThemeMode.system:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.system;
    }
  }
}
