import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/l10n/app_localizations.dart';
import 'package:hw_manager_flutter/routes/home_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:hw_manager_flutter/untis_util.dart';
import 'package:logger/logger.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';
import 'package:simple_secure_storage/simple_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final log = Logger(
    filter: NoFilter(), // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
    //output: null, // Use the default LogOutput (-> send everything to console)
  );
  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      bool enabled = false;
      String? host;
      int? port;
      try {
        final ProxySetting settings = await NativeProxyReader.proxySetting;
        enabled = settings.enabled;
        host = settings.host;
        port = settings.port;
        log.i("PROXY conf: h: $host, port: $port, enabled: $enabled");
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
      if (enabled && host != null) {
        final proxy = CustomProxy(ipAddress: host, port: port);
        proxy.enable();
        if (kDebugMode) {
          print("proxy enabled");
        }
      }
    }
    await SimpleSecureStorage.initialize();
  } else {
    // To secure your data on Flutter web, we have to encrypt it using a password and a salt.
    await SimpleSecureStorage.initialize(WebInitializationOptions(
        keyPassword:
            "thisismysupersecretpassword,thatnobodyshouldbeseeing right now.",
        encryptionSalt: "salty"));
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
  static HWMAppState of(BuildContext context) =>
      context.findAncestorStateOfType<HWMAppState>()!;
}

class HWMAppState extends State<HWMApp> {
  ThemeMode _themeMode = ThemeMode.system;

  late String packageVersion;

  void setVersion() async {
    final pubspec =
        await DefaultAssetBundle.of(context).loadString("pubspec.yaml");
    packageVersion = pubspec.split("version: ")[1].split("\n")[0];
  }

  @override
  void initState() {
    super.initState();
    setVersion();
    Preferences.getThemeMode().then((value) {
      setState(() => _themeMode = value);
    });
  }

  ThemeData _getAdjustedTheme([bool darkMode = false]) {
    final ColorScheme cScheme = darkMode
        ? ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: Colors.red.shade900,
            inversePrimary: Colors.red.shade900.withValues(alpha: 0.9),
            surfaceContainer: Colors.red.shade900,
            surfaceTint: Colors.grey.shade900,
          )
        : ColorScheme.fromSeed(seedColor: Colors.red.shade900);

    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      labelStyle: TextStyle(color: cScheme.primary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: WidgetStateInputBorder.resolveWith((Set<WidgetState> states) {
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
      dialogTheme: const DialogThemeData(
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          // Set the predictive back transitions for Android.
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
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
