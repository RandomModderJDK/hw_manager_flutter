import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/custom_settings_tile.dart';
import 'package:hw_manager_flutter/discord_util.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/main.dart';
import 'package:hw_manager_flutter/routes/discord_route.dart';
import 'package:hw_manager_flutter/routes/subject_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:hw_manager_flutter/untis_util.dart';
import 'package:nyxx/nyxx.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    //final BasicNotifier discordTokenNotifier = BasicNotifier();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(context.locals.settingsTitle),
        leading: BackButton(
          onPressed: () => Navigator.maybePop(context),
        ),
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
                onPressed: (context) => Preferences.nextThemeMode().then(
                  (themeMode) => HWMApp.of(context).changeTheme(themeMode),
                ),
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
                      SettingsTextFormField(
                        labelText: context.locals.settingsUntisLoginServer,
                        hintText: context.locals.settingsUntisLoginServerHint,
                        initValue: Preferences.getUntisServer(),
                        onChanged: (s) => Preferences.saveUntisServer(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      SettingsTextFormField(
                        labelText: context.locals.settingsUntisLoginSchool,
                        hintText: context.locals.settingsUntisLoginSchoolHint,
                        initValue: Preferences.getUntisSchool(),
                        onChanged: (s) => Preferences.saveUntisSchool(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      SettingsTextFormField(
                        labelText: context.locals.settingsUntisLoginUsername,
                        hintText: context.locals.settingsUntisLoginUsernameHint,
                        initValue: Preferences.getUntisUsername(),
                        onChanged: (s) => Preferences.saveUntisUsername(s ?? ""),
                      ),
                      const SizedBox(height: 10),
                      SettingsTextFormField(
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
                onPressed: (context) async => UntisHelper().loginWithPreferences().then(
                      (success) =>
                          success ? untisConfirmation(locals.untisLoginSuccess) : untisError(locals.untisLoginFailure),
                    ),
              ),
              HWMSettingsTile(
                title: Text(context.locals.settingsUntisImportTitle),
                leading: const Icon(Icons.cloud_download_outlined),
                description: Text(context.locals.settingsUntisImportDescription),
                onPressed: (context) async {
                  final List<UntisSubject> subjects;
                  try {
                    subjects = await UntisHelper().getCurrentUntisSubjects();
                  } catch (e) {
                    if (e is! ArgumentError) rethrow;
                    untisError(locals.untisLoginFailure);
                    return;
                  }
                  if (subjects.isEmpty) {
                    untisError(locals.untisLoginFailure);
                    return;
                  }
                  for (final UntisSubject subject in subjects) {
                    DBHelper.insertSubject(
                      Subject(
                        name: subject.longName,
                        shortName: subject.name,
                      ),
                    );
                  }
                  untisConfirmation(locals.settingsUntisImportSuccess);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text("Discord"),
            tiles: [
              // TODO: Add webhook appearance settings, i.e. username, avatarUrl
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
              HWMSettingsTile(
                title: SettingsTextFormField(
                  labelText: context.locals.settingsDiscordRelationsBotToken,
                  hintText: "OPdhu29hawopuhnUOUWE9awofhou.awdawdh34WDGGHH-Wawdsghj",
                  initValue: Preferences.getDiscordToken(),
                  onChanged: (s) async => Preferences.saveDiscordToken(s ?? ""),
                  onDeactivate: () async {
                    final String token = await Preferences.getDiscordToken();
                    if (DiscordHelper().tokenEqualsTo(token)) return;
                    discordStatusUpdate(locals.settingsDiscordRelationsBotTryToken);
                    final bool successfulLogin = await DiscordHelper().login(token);
                    final bool successfulGuildRefresh = await DiscordHelper().refreshGuildCache();
                    final bool successfulChannelRefresh = await DiscordHelper().refreshChannelCache();
                    if (successfulLogin && successfulGuildRefresh && successfulChannelRefresh) {
                      discordConfirmation(locals.settingsDiscordRelationsBotTryTokenSuccess);
                    } else {
                      discordError(locals.settingsDiscordRelationsBotTryTokenFailure);
                    }
                  },
                  onEnter: (s) {
                    Preferences.getDiscordToken().then((token) async {
                      if (!DiscordHelper().tokenEqualsTo(token)) {
                        discordStatusUpdate(locals.settingsDiscordRelationsBotTryToken);
                      }
                      if (!DiscordHelper().tokenEqualsTo(token) || DiscordHelper().tokenEqualsTo(null)) {
                        final bool successfulLogin = await DiscordHelper().login(token);
                        final bool successfulGuildRefresh = await DiscordHelper().refreshGuildCache();
                        final bool successfulChannelRefresh = await DiscordHelper().refreshChannelCache();
                        if (!(successfulLogin && successfulGuildRefresh && successfulChannelRefresh)) {
                          discordError(locals.settingsDiscordRelationsBotTryTokenFailure);
                          return null;
                        }
                        discordConfirmation(locals.settingsDiscordRelationsBotTryTokenSuccess);
                        DiscordHelper().loggedInNotifier.notifyListeners();
                      }
                    });
                    //discordTokenNotifier.notifyListeners();
                  },
                ),
                /*description: FutureBuilder(
                  future: Preferences.getWebhooksChannelID(),
                  builder: (context, channelIDSnap) => SettingsDropdownMenu<GuildChannel>(
                    menuEntries: () async {
                      final String token = await Preferences.getDiscordToken();
                      if (token.isEmpty) return null;
                      if (!DiscordHelper().tokenEqualsTo(token) || DiscordHelper().tokenEqualsTo(null)) {
                        final bool successfulLogin = await DiscordHelper().login(token);
                        final bool sucessfulGuildRefresh = await DiscordHelper().refreshGuildCache();
                        final bool sucessfulChannelRefresh = await DiscordHelper().refreshChannelCache();
                        if (!(successfulLogin && sucessfulGuildRefresh && sucessfulChannelRefresh)) {
                          discordError("Bot couldn't login");
                          return null;
                        }
                        discordConfirmation("Bot logged in");
                      }
                      return DiscordHelper().getCategorizedChannelEntries(await DiscordHelper().channels);
                    },
                    isEnabled: (entries) => entries.isNotEmpty,
                    initValue: (entries) async {
                      final String? id = await Preferences.getWebhooksChannelID();
                      if (id == null) return null;
                      return entries.map((e) => e.value).firstWhere((gc) => gc.id == Snowflake.parse(id));
                    },
                    onSelected: (gc) => Preferences.saveWebhooksChannelID(gc?.id.value.toString()),
                    labelText: context.locals.dialogSubjectChannelName,
                    hintText: context.locals.dialogSubjectChannelNameHint,
                    rebuildOnValueChange: discordTokenNotifier,
                  ),
                ),*/
                leading: const Icon(Icons.vpn_key_outlined),
              ),
              HWMSettingsTile(
                title: Text(context.locals.settingsDiscordRelationsImportTitle),
                description: Text(
                  context.locals.settingsDiscordRelationsImportDescription,
                ),
                onPressed: (context) async {
                  final String token = await Preferences.getDiscordToken();
                  if (!DiscordHelper().tokenEqualsTo(token)) {
                    discordStatusUpdate(locals.settingsDiscordRelationsBotTryToken);
                    final bool successfulLogin = await DiscordHelper().login(token);
                    final bool successfulGuildRefresh = await DiscordHelper().refreshGuildCache();
                    final bool successfulChannelRefresh = await DiscordHelper().refreshChannelCache();
                    if (!(successfulLogin && successfulGuildRefresh && successfulChannelRefresh)) {
                      discordError(locals.settingsDiscordRelationsBotTryTokenFailure);
                      return;
                    }
                  }
                  final List<DiscordRelation> relations = await DBHelper.retrieveDiscordRelations();
                  final Iterable<GuildChannel>? channels = (await DiscordHelper().channels)?.where(
                    (c) => !relations.map((r) => r.channelID).contains(c.id.value.toString()),
                  );
                  if (channels == null) {
                    discordError(locals.settingsDiscordRelationsImportFailure);
                    return;
                  }
                  int count = 0;
                  for (final GuildChannel c in channels) {
                    if (c is GuildCategory) continue;
                    final DiscordRelation dr = DiscordRelation(
                      channelID: c.id.value.toString(),
                      channelName: c.name,
                    );
                    if (kDebugMode) print("Added channel ${c.name} ${c.id.value}");
                    DBHelper.insertDiscordRelation(dr);
                    count++;
                  }
                  discordConfirmation(locals.settingsDiscordRelationsImportSuccess(count));
                },
                leading: const Icon(Icons.cloud_download_outlined),
              ),
              // TODO: Add button to automatically find the matching discord relation to a subject and connect them
              // TODO: At setting for strict subject names
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(String?)? onChanged;
  final void Function(String?)? onEnter;
  final void Function()? onDeactivate;

  final String? validatorMessage;
  final String labelText;
  final String hintText;
  final Future<String?>? initValue;
  final int maxLines;
  final bool autoTrim;

  final bool passwordStyle;

  const SettingsTextFormField({
    super.key,
    this.maxLines = 1,
    this.controller,
    this.validatorMessage,
    required this.labelText,
    required this.hintText,
    this.passwordStyle = false,
    this.autoTrim = true,
    this.initValue,
    this.onChanged,
    this.onEnter,
    this.onDeactivate,
  });

  @override
  State<SettingsTextFormField> createState() => _SettingsTextFormFieldState();
}

class _SettingsTextFormFieldState extends State<SettingsTextFormField> {
  late TextEditingController _controller;
  late Function(dynamic) onFinishEditing;

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController(text: "");
    widget.initValue?.then((value) => _controller.text = value ?? "");
    super.initState();
  }

  @override
  void deactivate() {
    widget.onDeactivate?.call();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      validator: (value) => value!.isEmpty ? widget.validatorMessage : null,
      maxLines: widget.maxLines,
      obscureText: widget.passwordStyle,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      onChanged: (s) {
        if (widget.autoTrim) {
          if (s.trim() != s) setState(() => _controller.text = s.trim()); // Remove whitespace immediately
          s = s.trim();
        }
        widget.onChanged?.call(s);
      },
      onFieldSubmitted: (s) => widget.onEnter?.call(widget.autoTrim ? s.trim() : s),
      //onTapOutside: onFinishEditing, // disabled because it break the focus system
    );
  }
}

class SettingsDropdownMenu<T> extends StatefulWidget {
  final bool Function(List<DropdownMenuEntry<T>>)? isEnabled;

  final Future<Iterable<DropdownMenuEntry<T>>?> Function() menuEntries;
  final void Function(T?) onSelected;
  final Future<T?> Function(Iterable<DropdownMenuEntry<T>>)? initValue;

  final String labelText;
  final String hintText;

  final ChangeNotifier? rebuildOnValueChange;

  const SettingsDropdownMenu({
    super.key,
    this.isEnabled,
    required this.menuEntries,
    required this.onSelected,
    required this.labelText,
    required this.hintText,
    this.rebuildOnValueChange,
    this.initValue,
  });

  @override
  State<SettingsDropdownMenu<T>> createState() => _SettingsDropdownMenuState();
}

class _SettingsDropdownMenuState<T> extends State<SettingsDropdownMenu<T>> {
  List<DropdownMenuEntry<T>> menuEntries = [];
  T? initValue;

  @override
  void initState() {
    widget.rebuildOnValueChange?.addListener(
      () => widget.menuEntries().then((entries) async {
        if (kDebugMode) {
          print("ENTRIES AFTER NOTIFY: $entries");
        }
        super.setState(() {
          menuEntries = entries?.toList(growable: false) ?? [];
        });
      }),
    );
    widget.menuEntries().then((entries) async {
      T? initValue;
      if (entries != null && entries.isNotEmpty) {
        initValue = await widget.initValue?.call(entries);
      }
      super.setState(() {
        menuEntries = entries?.toList(growable: false) ?? [];
        this.initValue = initValue;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      enabled: widget.isEnabled != null && widget.isEnabled!(menuEntries),
      menuHeight: 250,
      onSelected: widget.onSelected,
      requestFocusOnTap: true,
      inputDecorationTheme: Theme.of(context).inputDecorationTheme,
      hintText: widget.hintText,
      label: Text(widget.labelText),
      initialSelection: initValue,
      dropdownMenuEntries: menuEntries,
      expandedInsets: EdgeInsets.zero,
    );
  }
}
