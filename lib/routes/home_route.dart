import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hw_manager_flutter/dialogs/dialog_homework_form.dart';
import 'package:hw_manager_flutter/dialogs/dialog_subject_form.dart';
import 'package:hw_manager_flutter/discord_util.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/list_tiles.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/routes/settings_route.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key});

  static HomeRouteState? of(BuildContext context) => context.findAncestorStateOfType<HomeRouteState>();

  @override
  State<HomeRoute> createState() => HomeRouteState();
}

class HomeRouteState extends State<HomeRoute> {
  Widget hwListWidget() {
    return FutureBuilder(
      future: DBHelper.retrieveHomeworks(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FloatingButtonCardListView(
            itemCount: snapshot.data!.length,
            child: (position) => HWListItem(
              homework: snapshot.data![position],
              onEdit: () async => showDialog(
                context: context,
                builder: (context) => HomeworkFormDialog(
                  homework: snapshot.data![position],
                  title: context.locals.dialogHWEditTitle,
                  submit: context.locals.dialogHWEdit,
                  cancel: context.locals.dialogHWEditCancel,
                ),
              ).then((v) {
                if (v == true) setState(() {});
                // TODO: Implement asking for edit of discord message, when one exists
              }),
              onDeleted: (DismissDirection direction) async {
                final Homework hw = snapshot.data![position];
                SubjectFormDialog.subjectRelationNotifier.addListener(() => setState((){}));
                final List<HWPage> pages = await DBHelper.retrieveHWPages(hw);
                snapshot.data!.remove(hw);
                await DBHelper.deleteHomework(hw);
                if (hw.subject.discordChannel != null) {
                  if (hw.subject.discordChannel!.webhookUrl != null) {
                    final String url = hw.subject.discordChannel!.webhookUrl!;
                    await DiscordHelper().deleteWebhookMessage(url, hw);
                  }
                }
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.locals.deleteHWToast(hw.id!, hw.subject.name)),
                      action: SnackBarAction(
                        label: context.locals.deleteHWToastUndo,
                        onPressed: () => Future.wait([
                          DBHelper.insertHomework(hw),
                          DBHelper.insertHWPages(pages),
                        ]).then((value) => setState(() {})),
                      ),
                    ),
                  );
                });
              },
            ),
          );
        } else {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                Text('Loading Database...\nMaybe check logs?'),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    DiscordHelper().loggedInNotifier.addListener(() => setState((){}));
    SubjectFormDialog.subjectRelationNotifier.addListener(() => setState((){}));
    () async {
      final token = await Preferences.getDiscordToken();
      if (DiscordHelper().tokenEqualsTo(null) && !DiscordHelper().isLoggedIn && token.isNotEmpty) {
        final bool successfulLogin = await DiscordHelper().login(token);
        final bool successfulGuildRefresh = await DiscordHelper().refreshGuildCache();
        final bool successfulChannelRefresh = await DiscordHelper().refreshChannelCache();
        if (!(successfulLogin && successfulGuildRefresh && successfulChannelRefresh)) {
          discordError(locals.settingsDiscordRelationsBotTryTokenFailure);
          return;
        }
        discordConfirmation(locals.settingsDiscordRelationsBotTryTokenSuccess);
        setState(() {});
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final FToast fToast = FToast();
    fToast.init(context);
    Intl.defaultLocale = Localizations.localeOf(context).languageCode;
    initializeDateFormatting();
    initLocals(context); // Init AppLocalizations variable in general_util.dart
    if (kDebugMode) {
      print("REBUILD");
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(context.locals.homeTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: locals.discordHomeworkFetchTitle,
            onPressed: !DiscordHelper().isLoggedIn
                ? null
                : () => DiscordHelper().fetchHomework().then((map) async {
              /*void Function(String text) discordError =
                      (String text) => HWMToast(text: text, color: Colors.red, icon: const Icon(Icons.cloud_sync_outlined)).show();*/
              void fetchConfirmation(String text) =>
                  HWMToast(text: text, color: Colors.green.shade900, icon: const Icon(Icons.cloud_sync_outlined)).show();
              void fetchStatusUpdate(String text) =>
                  HWMToast(text: text, color: Colors.yellow.shade700, icon: const Icon(Icons.cloud_sync_outlined)).show();
              int totCount = map.length;
              int overwriteCount = 0;
              map.forEach((hw, pagesData) async {
                final Homework? existingHomework = await DBHelper.getHomeworkByMessageID(hw.messageID!);
                if (existingHomework != null) {
                  overwriteCount++;
                  if (kDebugMode) {
                    print("${existingHomework.content} was overwritten");
                  }
                  hw.id = existingHomework.id; // TODO: Maybe ask for confirmation to overwrite
                }
                if (totCount == 1) {
                  fetchConfirmation(locals.discordHomeworkFetchSuccess(map.length, map.length-overwriteCount));
                  fetchStatusUpdate(locals.discordHomeworkFetchLocalOverwriteStatus(overwriteCount));
                } else {
                  totCount--;
                }
                hw.id = await DBHelper.insertHomework(hw);
                final List<HWPage> pages = [];
                for (int i = 0; i < pagesData.length; i++) {
                  pages.add(HWPage(hw.id!, pagesData[i], order: i));
                }
                DBHelper.insertHWPages(pages.toList());
                setState(() {});
              });
            }),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsRoute()),
              ),
          ),
        ],
      ),
      body: hwListWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog(
          context: context,
          builder: (context) => HomeworkFormDialog(
            title: context.locals.dialogHWAddTitle,
            submit: context.locals.dialogHWAdd,
            cancel: context.locals.dialogHWAddCancel,
          ),
        ).then((dynamic v) {
          if (v == true) setState(() {});
        }),
        tooltip: context.locals.dialogHWAddTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
