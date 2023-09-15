import 'package:dart_webuntis/untis.dart' as untis;
import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hw_manager_flutter/routes/subject_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:hw_manager_flutter/untis_util.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:settings_ui/src/utils/theme_provider.dart';

import '../main.dart';
import '../shared_preferences.dart';

class SettingsRoute extends StatelessWidget {
  SettingsRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeProvider.getTheme(
        context: context, platform: PlatformUtils.detectPlatform(context), brightness: Theme.of(context).brightness);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: SettingsList(
        sections: [
          SettingsSection(title: const Text('General'), tiles: [
            SettingsTile(
              title: const Text('Dark Mode'),
              leading: const Icon(Icons.dark_mode_outlined),
              description: const Text('Change between dark, light, automatic mode'),
              onPressed: (context) {
                Preferences.nextThemeMode().then((mode) => HWMApp.of(context).changeTheme(mode));
              },
            ),
            SettingsTile(
              title: const Text('Subjects overview'),
              leading: const Icon(Icons.subject),
              description: const Text('Delete, insert or edit the suggested subjects'),
              onPressed: (context) =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SubjectRoute())),
            )
          ]),
          SettingsSection(title: const Text('Untis'), tiles: [
            SettingsTile(
                title: const Text('Login'),
                leading: const Icon(Icons.login_rounded),
                description: Expandable(
                    backgroundColor: themeData.settingsListBackground!,
                    boxShadow: const [],
                    centralizeFirstChild: false,
                    arrowWidget: const Icon(Icons.keyboard_arrow_up_rounded, size: 40.0),
                    firstChild: const Expanded(
                        child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Login with your Untis school account'),
                    )),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        UntisTextFormField(
                            labelText: "Server",
                            hintText: "lorem.untis.com",
                            initValue: Preferences.getUntisServer(),
                            onChanged: (s) => Preferences.saveUntisServer(s ?? "")),
                        const SizedBox(height: 10),
                        UntisTextFormField(
                            labelText: "School",
                            hintText: "max+schl",
                            initValue: Preferences.getUntisSchool(),
                            onChanged: (s) => Preferences.saveUntisSchool(s ?? "")),
                        const SizedBox(height: 10),
                        UntisTextFormField(
                            labelText: "Username",
                            hintText: "maxmustermann",
                            initValue: Preferences.getUntisUsername(),
                            onChanged: (s) => Preferences.saveUntisUsername(s ?? "")),
                        const SizedBox(height: 10),
                        UntisTextFormField(
                            passwordStyle: true,
                            labelText: "Password",
                            hintText: "mypass1234",
                            initValue: Preferences.getUntisPassword(),
                            onChanged: (s) => Preferences.saveUntisPassword(s ?? ""))
                      ],
                    ))),
            SettingsTile(
              title: const Text('Import subjects'),
              leading: const Icon(Icons.cloud_download_rounded),
              description: const Text('Fetch subjects from untis'),
              onPressed: (context) async {
                FToast fToast = FToast();
                fToast.init(context);

                List<untis.Subject> subjects = await UntisHelper().getCurrentSubjects();
                if (subjects.isEmpty) {
                  Widget toast = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: Colors.redAccent.withOpacity(0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sms_failed_rounded),
                        SizedBox(
                          width: 12.0,
                        ),
                        Text("Failed to log in"),
                      ],
                    ),
                  );
                  fToast.showToast(child: toast);
                  return;
                }
                for (untis.Subject subject in subjects) {
                  DBHelper().insertSubject(Subject(name: subject.longName, shortName: subject.name));
                }
                Widget toast = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.0),
                    color: Colors.greenAccent.withOpacity(0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check),
                      SizedBox(
                        width: 12.0,
                      ),
                      Text("Imported untis subjects"),
                    ],
                  ),
                );
                fToast.showToast(child: toast);
              },
            ),
          ])
        ],
      ),
    );
  }
}

class UntisTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(String?)? onChanged;

  final String? validatorMessage;
  final String labelText;
  final String hintText;
  final Future<String?>? initValue;
  final int maxLines;

  final bool passwordStyle;

  const UntisTextFormField(
      {Key? key,
      this.maxLines = 1,
      this.controller,
      this.validatorMessage,
      required this.labelText,
      required this.hintText,
      this.passwordStyle = false,
      this.initValue,
      this.onChanged})
      : super(key: key);

  @override
  State<UntisTextFormField> createState() => _UntisTextFormFieldState();
}

class _UntisTextFormFieldState extends State<UntisTextFormField> {
  TextEditingController? _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: "");
    widget.initValue?.then((value) => _controller?.text = value ?? "");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller ?? _controller,
      validator: (value) => value!.isEmpty ? widget.validatorMessage : null,
      maxLines: widget.maxLines,
      obscureText: widget.passwordStyle,
      decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: MaterialStateOutlineInputBorder.resolveWith((Set<MaterialState> states) {
            final Color color = states.contains(MaterialState.error)
                ? Color.alphaBlend(
                    Theme.of(context).colorScheme.primary.withAlpha(125), Theme.of(context).colorScheme.inversePrimary)
                : Theme.of(context).colorScheme.primary;
            return OutlineInputBorder(borderSide: BorderSide(color: color));
          }),
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
          hintText: widget.hintText,
          errorStyle: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
          errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.inversePrimary))),
      onChanged: widget.onChanged,
    );
  }
}
