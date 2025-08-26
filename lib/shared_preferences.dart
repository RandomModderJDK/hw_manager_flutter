import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_secure_storage/simple_secure_storage.dart';

mixin Preferences {
  static const themeStatus = "THEMESTATUS";

  static const untisServer = "UNTIS.SERVER";
  static const untisSchool = "UNTIS.SCHOOL";
  static const untisUsername = "UNTIS.USERNAME";
  static const untisPassword = "UNTIS.PASSWORD";

  static const discordBotToken = "DISCORD.TOKEN";

  //static const discordWebhookChannel = "DISCORD.WEBHOOKCHANNEL";

  static Future<void> saveUntisServer(String server) => SimpleSecureStorage.write(untisServer, server);

  static Future<void> saveUntisSchool(String school) => SimpleSecureStorage.write(untisSchool, school);

  static Future<void> saveUntisUsername(String username) => SimpleSecureStorage.write(untisUsername, username);

  static Future<void> saveUntisPassword(String password) => SimpleSecureStorage.write(untisPassword, password);

  static Future<String?> getUntisServer() => SimpleSecureStorage.read(untisServer);

  static Future<String?> getUntisSchool() => SimpleSecureStorage.read(untisSchool);

  static Future<String?> getUntisUsername() => SimpleSecureStorage.read(untisUsername);

  static Future<String?> getUntisPassword() => SimpleSecureStorage.read(untisPassword);

  static Future<void> saveDiscordToken(String token) => SimpleSecureStorage.write(discordBotToken, token);

  static Future<String> getDiscordToken() async => await SimpleSecureStorage.read(discordBotToken) ?? "";

  //static Future<void> saveWebhooksChannelID(String? id) => SimpleSecureStorage.write(key: discordWebhookChannel, value: id);

  //static Future<String?> getWebhooksChannelID() async => await SimpleSecureStorage.read(key: discordWebhookChannel);

  /// 0 - Automatic (System)
  /// 1 - Light
  /// 2 - Dark
  static Future<void> setThemeMode(ThemeMode mode) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    prefs.setString(themeStatus, mode.name);
  }

  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String mName = await prefs.getString(themeStatus) ?? "system";
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
