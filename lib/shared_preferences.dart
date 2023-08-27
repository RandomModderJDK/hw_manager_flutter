import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const themeStatus = "THEMESTATUS";

  static const persistDialog = "DIALOGPERSISTING";

  /// 0 - Automatic (System)
  /// 1 - Light
  /// 2 - Dark
  static setThemeMode(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(themeStatus, mode.name);
  }

  static Future<ThemeMode> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String mName = (prefs.getString(themeStatus) ?? "system");
    ThemeMode mode = ThemeMode.values.firstWhere((m) => m.name == mName);
    return mode;
  }

  static Future<ThemeMode> nextThemeMode() async {
    switch (await getThemeMode()) {
      case ThemeMode.system:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.system;
    }
  }

  static setDialogPersistence(bool persisting) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(persistDialog, persisting);
    if (kDebugMode) {
      print("Dialog persistence is now $persisting");
    }
  }

  static Future<bool> getDialogPersistence() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool persisting = prefs.getBool(persistDialog) ?? false;
    return persisting;
  }
}
