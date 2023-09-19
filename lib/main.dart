import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hw_manager_flutter/routes/home_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';

void main() {
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HWM',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        dialogTheme:
            const DialogTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        dialogTheme:
            const DialogTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.red.shade900,
          surfaceTint: Colors.grey.shade900,
        ),
        useMaterial3: true,
      ),
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
