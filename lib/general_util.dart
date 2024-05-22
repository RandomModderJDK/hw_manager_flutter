import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

extension MyBuildContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Color get primaryColor => colorScheme.primary;

  Color get inversePrimaryColor => colorScheme.inversePrimary;

  Color get backgroundColor => colorScheme.background;

  AppLocalizations get locals => AppLocalizations.of(this)!;
}

AppLocalizations? _l;

AppLocalizations get locals => _l!;

void initLocals(BuildContext context) => _l = AppLocalizations.of(context);

class ConfirmationToast extends StatelessWidget {
  final String text;

  const ConfirmationToast({super.key, required this.text});

  @override
  Widget build(BuildContext context) => HWMToast(
        color: Colors.green.shade900.withOpacity(0.8),
        icon: const Icon(Icons.check),
        text: text,
      );

  void show() => FToast().showToast(child: this);
}

class ErrorToast extends StatelessWidget {
  final String text;

  const ErrorToast({super.key, required this.text});

  @override
  Widget build(BuildContext context) => HWMToast(
        color: Colors.redAccent.withOpacity(0.8),
        icon: const Icon(Icons.sms_failed_rounded),
        text: text,
      );

  void show() => FToast().showToast(child: this);
}

class HWMToast extends StatelessWidget {
  final Color color;
  final Icon? icon;
  final String text;

  const HWMToast({required this.color, required this.icon, required this.text});

  void show() => FToast().showToast(child: this);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon!,
          if (icon != null) const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              style: DialogTheme.of(context).contentTextStyle,
              text,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class BasicNotifier extends ChangeNotifier {
  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}
