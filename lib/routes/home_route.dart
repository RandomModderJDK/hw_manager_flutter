import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hw_manager_flutter/dialogs/dialog_homework_form.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/list_tiles.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/routes/settings_route.dart';
//import 'package:hw_manager_flutter/routes/synchronize_route.dart';
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
                  title: context.locals.dialogHWEditTitle,
                  submit: context.locals.dialogHWEdit,
                  cancel: context.locals.dialogHWEditCancel,
                ),
              ).then((v) {
                if (v == true) setState(() {});
              }),
              onDeleted: (DismissDirection direction) async {
                final Homework hw = snapshot.data![position];
                final List<HWPage> pages = await DBHelper().retrieveHWPages(hw);
                snapshot.data!.remove(hw);
                await DBHelper().deleteHomework(hw);
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.locals.deleteHWToast(hw.id!, hw.subject.name),
                      ),
                      action: SnackBarAction(
                        label: context.locals.deleteHWToastUndo,
                        onPressed: () => Future.wait([
                          DBHelper().insertHomework(hw),
                          DBHelper().insertHWPages(pages),
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
    dbHelper = DBHelper();
    dbHelper.initDBs().whenComplete(() async {
      setState(() {});
    });
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
          /*IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SynchronizeRoute(),
              ),
            ),
          ),*/
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
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
