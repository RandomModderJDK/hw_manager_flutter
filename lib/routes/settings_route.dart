import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hw_manager_flutter/custom_settings_tile.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/main.dart';
import 'package:hw_manager_flutter/routes/discord_route.dart';
import 'package:hw_manager_flutter/routes/subject_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:hw_manager_flutter/untis_util.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(context.locals.settingsTitle),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(context.locals.settingsGeneral),
            tiles: [
              HWMSettingsTile(
                title: Text(context.locals.settingsThemeModeTitle),
                leading: const Icon(Icons.dark_mode_outlined),
                description: Text(context.locals.settingsThemeModeDescription),
                onPressed: (context) =>
                    Preferences.nextThemeMode().then((themeMode) => HWMApp.of(context).changeTheme(themeMode)),
              ),
              HWMSettingsTile(
                title: Text(context.locals.settingsSubjectsTitle),
                leading: const Icon(Icons.subject),
                description: Text(
                  context.locals.settingsSubjectsDescription,
                ),
                onPressed: (context) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubjectRoute(),
                  ),
                ),
              ),
            ],
          ),
          // Untis Section
          SettingsSection(
            title: Text(context.locals.settingsUntis),
            tiles: [
              HWMSettingsTile(
                title: Text(
                  context.locals.settingsUntisLoginTitle,
                ),
                leading: const Icon(Icons.login_rounded),
                description: Expandable(
                  backgroundColor: Colors.transparent,
                  boxShadow: const [],
                  centralizeFirstChild: false,
                  arrowWidget: const Icon(Icons.keyboard_arrow_up_rounded, size: 40.0),
                  firstChild: Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.locals.settingsUntisLoginDescription,
                      ),
                    ),
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        labelText: context.locals.settingsUntisLoginServer,
                        hintText: context.locals.settingsUntisLoginServerHint,
                        initValue: Preferences.getUntisServer(),
                        onChanged: (s) => Preferences.saveUntisServer(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        labelText: context.locals.settingsUntisLoginSchool,
                        hintText: context.locals.settingsUntisLoginSchoolHint,
                        initValue: Preferences.getUntisSchool(),
                        onChanged: (s) => Preferences.saveUntisSchool(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        labelText: context.locals.settingsUntisLoginUsername,
                        hintText: context.locals.settingsUntisLoginUsernameHint,
                        initValue: Preferences.getUntisUsername(),
                        onChanged: (s) => Preferences.saveUntisUsername(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        passwordStyle: true,
                        labelText: context.locals.settingsUntisLoginPassword,
                        hintText: context.locals.settingsUntisLoginPasswordHint,
                        initValue: Preferences.getUntisPassword(),
                        onChanged: (s) => Preferences.saveUntisPassword(s ?? ""),
                      ),
                    ],
                  ),
                ),
              ),
              HWMSettingsTile(
                title: Text(context.locals.settingsUntisTestLoginTitle),
                leading: const Icon(Icons.task_alt_rounded),
                description: Text(context.locals.settingsUntisTestLoginDescription),
                onPressed: (context) async {
                  if (await UntisHelper().loginWithPreferences()) {
                    FToast().showToast(child: ErrorToast(text: locals.untisLoginFailure));
                    return;
                  }
                  FToast().showToast(child: ConfirmationToast(text: locals.untisLoginSuccess));
                },
              ),
              HWMSettingsTile(
                title: Text(context.locals.settingsUntisImportTitle),
                leading: const Icon(Icons.cloud_download_rounded),
                description: Text(context.locals.settingsUntisImportDescription),
                onPressed: (context) async {
                  final List<UntisSubject> subjects = await UntisHelper().getCurrentUntisSubjects();
                  if (subjects.isEmpty) {
                    FToast().showToast(child: ErrorToast(text: locals.untisLoginFailure));
                    return;
                  }
                  for (final UntisSubject subject in subjects) {
                    DBHelper().insertSubject(Subject(name: subject.longName, shortName: subject.name));
                  }
                  FToast().showToast(child: ConfirmationToast(text: locals.settingsUntisImportSuccess));
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text("Discord"),
            tiles: [
              HWMSettingsTile(
                title: Text(context.locals.settingsDiscordRelationsTitle),
                leading: const Icon(Icons.subject),
                description: Text(
                  context.locals.settingsDiscordRelationsDescription,
                ),
                onPressed: (context) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DiscordRoute(),
                  ),
                ),
              ),
            ],
          ),
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

  const UntisTextFormField({
    super.key,
    this.maxLines = 1,
    this.controller,
    this.validatorMessage,
    required this.labelText,
    required this.hintText,
    this.passwordStyle = false,
    this.initValue,
    this.onChanged,
  });

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
        hintText: widget.hintText,
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      onChanged: widget.onChanged,
    );
  }
}
