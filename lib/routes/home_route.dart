import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hw_manager_flutter/dialogs/dialog_homework_form.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/routes/settings_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../list_tiles.dart';

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key});

  static HomeRouteState? of(BuildContext context) => context.findAncestorStateOfType<HomeRouteState>();

  @override
  State<HomeRoute> createState() => HomeRouteState();
}

class HomeRouteState extends State<HomeRoute> {
  late DBHelper dbHelper;

  Widget hwListWidget() {
    return FutureBuilder(
        future: dbHelper.retrieveHomeworks(),
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
                            title: AppLocalizations.of(context)!.dialogHWEditTitle,
                            submit: AppLocalizations.of(context)!.dialogHWEdit,
                            cancel: AppLocalizations.of(context)!.dialogHWEditCancel,
                          ),
                        ).then((v) {
                          if (v ?? false) setState(() {});
                        }),
                    onDeleted: (DismissDirection direction) async {
                      Homework hw = snapshot.data![position];
                      List<HWPage> pages = await DBHelper().retrieveHWPages(hw);
                      snapshot.data!.remove(hw);
                      await DBHelper().deleteHomework(hw);
                      setState(() {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.deleteHWToast(hw.id!, hw.subject.name)),
                            action: SnackBarAction(
                                label: AppLocalizations.of(context)!.deleteHWToastUndo,
                                onPressed: () =>
                                    Future.wait([DBHelper().insertHomework(hw), DBHelper().insertHWPages(pages)])
                                        .then((value) => setState(() {}))),
                          ),
                        );
                      });
                    }));
          } else {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[CircularProgressIndicator(), Text('Loading Database...\nMaybe check logs?')]));
          }
        });
  }

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    dbHelper.initDBs().whenComplete(() async {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = Localizations.localeOf(context).languageCode;
    initializeDateFormatting();
    if (kDebugMode) {
      print("REBUILD");
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(AppLocalizations.of(context)!.homeTitle),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsRoute()),
                    ))
          ]),
      body: hwListWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog(
          context: context,
          builder: (context) => HomeworkFormDialog(
            title: AppLocalizations.of(context)!.dialogHWAddTitle,
            submit: AppLocalizations.of(context)!.dialogHWAdd,
            cancel: AppLocalizations.of(context)!.dialogHWAddCancel,
          ),
        ).then((v) {
          if (v ?? false) setState(() {});
        }),
        tooltip: AppLocalizations.of(context)!.dialogHWAddTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
