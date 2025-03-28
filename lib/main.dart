import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http_proxy/http_proxy.dart';
import 'package:hw_manager_flutter/routes/home_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';

void main() async {
  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsFlutterBinding.ensureInitialized();
      final HttpProxy httpProxy = await HttpProxy.createHttpProxy();
      HttpOverrides.global = httpProxy;
    }
  }
  await DBHelper().initDBs();
  runApp(const HWMApp());
}

class HWMApp extends StatefulWidget {
  const HWMApp({super.key});

  @override
  HWMAppState createState() => HWMAppState();

  /// InheritedWidget style accessor to our State object.
  // ignore: unreachable_from_main
  static HWMAppState of(BuildContext context) => context.findAncestorStateOfType<HWMAppState>()!;
}

class HWMAppState extends State<HWMApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    Preferences.getThemeMode().then((value) {
      setState(() => _themeMode = value);
    });
  }

  ThemeData _getAdjustedTheme([bool darkMode = false]) {
    final ColorScheme cScheme = darkMode
        ? ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: Colors.red.shade900,
            inversePrimary: Colors.red.shade900.withOpacity(0.9),
            surfaceContainer: Colors.red.shade900,
            surfaceTint: Colors.grey.shade900,
          )
        : ColorScheme.fromSeed(seedColor: Colors.red.shade900);

    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      labelStyle: TextStyle(color: cScheme.primary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: MaterialStateOutlineInputBorder.resolveWith((Set<WidgetState> states) {
        final Color color = states.contains(WidgetState.focused)
            ? Color.alphaBlend(
                cScheme.primary.withAlpha(125),
                cScheme.inversePrimary,
              )
            : cScheme.primary;
        return OutlineInputBorder(
          borderSide: BorderSide(width: 1.3, color: color),
        );
      }),
      errorStyle: TextStyle(color: cScheme.inversePrimary),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cScheme.inversePrimary),
      ),
    );

    return ThemeData(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: cScheme.primary,
          backgroundColor: cScheme.inversePrimary,
        ),
      ),
      dialogTheme: const DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      colorScheme: cScheme,
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: inputDecorationTheme,
        menuStyle: const MenuStyle(
          padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
        ),
      ),
      inputDecorationTheme: inputDecorationTheme,
      useMaterial3: true,
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HWM',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: AppLocalizations.supportedLocales.first,
      theme: _getAdjustedTheme(),
      darkTheme: _getAdjustedTheme(true),
      themeMode: _themeMode,
      // device controls theme
      home: const HomeRoute(),
    );
  }

  // ignore: unreachable_from_main
  void changeTheme(ThemeMode themeMode) {
    Preferences.setThemeMode(themeMode);
    setState(() {
      _themeMode = themeMode;
      if (kDebugMode) {
        print(themeMode);
      }
    });
  }
}
