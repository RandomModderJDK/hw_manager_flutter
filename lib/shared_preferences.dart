import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin Preferences {
  static const themeStatus = "THEMESTATUS";

  static const untisServer = "UNTIS.SERVER";
  static const untisSchool = "UNTIS.SCHOOL";
  static const untisUsername = "UNTIS.USERNAME";
  static const untisPassword = "UNTIS.PASSWORD";

  static AndroidOptions _getAndroidOptions() => const AndroidOptions(encryptedSharedPreferences: true);
  static final FlutterSecureStorage _storage = FlutterSecureStorage(aOptions: _getAndroidOptions());

  static Future<void> saveUntisServer(String server) => _storage.write(key: untisServer, value: server);

  static Future<void> saveUntisSchool(String school) => _storage.write(key: untisSchool, value: school);

  static Future<void> saveUntisUsername(String username) => _storage.write(key: untisUsername, value: username);

  static Future<void> saveUntisPassword(String password) => _storage.write(key: untisPassword, value: password);

  static Future<String?> getUntisServer() => _storage.read(key: untisServer);

  static Future<String?> getUntisSchool() => _storage.read(key: untisSchool);

  static Future<String?> getUntisUsername() => _storage.read(key: untisUsername);

  static Future<String?> getUntisPassword() => _storage.read(key: untisPassword);

  /// 0 - Automatic (System)
  /// 1 - Light
  /// 2 - Dark
  static Future<void> setThemeMode(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(themeStatus, mode.name);
  }

  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String mName = prefs.getString(themeStatus) ?? "system";
    final ThemeMode mode = ThemeMode.values.firstWhere((m) => m.name == mName);
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
}
