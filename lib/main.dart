import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  static HWMAppState of(BuildContext context) =>
      context.findAncestorStateOfType<HWMAppState>()!;
}

class HWMAppState extends State<HWMApp> {
  /// 1) our themeMode "state" field
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
      theme: ThemeData(
        dialogTheme: const DialogTheme(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)))),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        dialogTheme: const DialogTheme(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)))),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.red.shade900,
          surfaceTint: Colors.grey.shade900,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      // device controls theme
      home: const HomeRoute(title: 'Manage homework'),
    );
  }

  /// 3) Call this to change theme from any context using "of" accessor
  /// e.g.:
  /// MyApp.of(context).changeTheme(ThemeMode.dark);
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
