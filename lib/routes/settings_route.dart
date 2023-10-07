import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hw_manager_flutter/main.dart';
import 'package:hw_manager_flutter/routes/subject_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:hw_manager_flutter/untis_util.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:settings_ui/src/utils/theme_provider.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeProvider.getTheme(
      context: context,
      platform: PlatformUtils.detectPlatform(context),
      brightness: Theme.of(context).brightness,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.settingsGeneral),
            tiles: [
              SettingsTile(
                title:
                    Text(AppLocalizations.of(context)!.settingsThemeModeTitle),
                leading: const Icon(Icons.dark_mode_outlined),
                description: Text(
                  AppLocalizations.of(context)!.settingsThemeModeDescription,
                ),
                onPressed: (context) => Preferences.nextThemeMode().then(
                  (themeMode) => HWMApp.of(context).changeTheme(themeMode),
                ),
              ),
              SettingsTile(
                title:
                    Text(AppLocalizations.of(context)!.settingsSubjectsTitle),
                leading: const Icon(Icons.subject),
                description: Text(
                  AppLocalizations.of(context)!.settingsSubjectsDescription,
                ),
                onPressed: (context) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubjectRoute(),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.settingsUntis),
            tiles: [
              SettingsTile(
                title:
                    Text(AppLocalizations.of(context)!.settingsUntisLoginTitle),
                leading: const Icon(Icons.login_rounded),
                description: Expandable(
                  backgroundColor: themeData.settingsListBackground!,
                  boxShadow: const [],
                  centralizeFirstChild: false,
                  arrowWidget:
                      const Icon(Icons.keyboard_arrow_up_rounded, size: 40.0),
                  firstChild: Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!
                            .settingsUntisLoginDescription,
                      ),
                    ),
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        labelText: AppLocalizations.of(context)!
                            .settingsUntisLoginServer,
                        hintText: AppLocalizations.of(context)!
                            .settingsUntisLoginServerHint,
                        initValue: Preferences.getUntisServer(),
                        onChanged: (s) => Preferences.saveUntisServer(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        labelText: AppLocalizations.of(context)!
                            .settingsUntisLoginSchool,
                        hintText: AppLocalizations.of(context)!
                            .settingsUntisLoginSchoolHint,
                        initValue: Preferences.getUntisSchool(),
                        onChanged: (s) => Preferences.saveUntisSchool(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        labelText: AppLocalizations.of(context)!
                            .settingsUntisLoginUsername,
                        hintText: AppLocalizations.of(context)!
                            .settingsUntisLoginUsernameHint,
                        initValue: Preferences.getUntisUsername(),
                        onChanged: (s) =>
                            Preferences.saveUntisUsername(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      UntisTextFormField(
                        passwordStyle: true,
                        labelText: AppLocalizations.of(context)!
                            .settingsUntisLoginPassword,
                        hintText: AppLocalizations.of(context)!
                            .settingsUntisLoginPasswordHint,
                        initValue: Preferences.getUntisPassword(),
                        onChanged: (s) =>
                            Preferences.saveUntisPassword(s ?? ""),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsTile(
                title: Text(
                  AppLocalizations.of(context)!.settingsUntisImportTitle,
                ),
                leading: const Icon(Icons.cloud_download_rounded),
                description: Text(
                  AppLocalizations.of(context)!.settingsUntisImportDescription,
                ),
                onPressed: (context) async {
                  final FToast fToast = FToast();
                  fToast.init(context);
                  final String failure =
                      AppLocalizations.of(context)!.settingsUntisImportFailure;
                  final String success =
                      AppLocalizations.of(context)!.settingsUntisImportSuccess;

                  final List<UntisSubject> subjects =
                      await UntisHelper().getCurrentUntisSubjects();
                  if (subjects.isEmpty) {
                    final Widget toast = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        color: Colors.redAccent.withOpacity(0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sms_failed_rounded),
                          const SizedBox(width: 12.0),
                          Text(failure),
                        ],
                      ),
                    );
                    fToast.showToast(child: toast);
                    return;
                  }
                  for (final UntisSubject subject in subjects) {
                    DBHelper().insertSubject(
                      Subject(
                        name: subject.longName,
                        shortName: subject.name,
                      ),
                    );
                  }
                  final Widget toast = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: Colors.greenAccent.withOpacity(0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check),
                        const SizedBox(width: 12.0),
                        Text(success),
                      ],
                    ),
                  );
                  fToast.showToast(child: toast);
                },
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
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: MaterialStateOutlineInputBorder.resolveWith(
            (Set<MaterialState> states) {
          final Color color = states.contains(MaterialState.error)
              ? Color.alphaBlend(
                  Theme.of(context).colorScheme.primary.withAlpha(125),
                  Theme.of(context).colorScheme.inversePrimary,
                )
              : Theme.of(context).colorScheme.primary;
          return OutlineInputBorder(borderSide: BorderSide(color: color));
        }),
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
        hintText: widget.hintText,
        errorStyle:
            TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
