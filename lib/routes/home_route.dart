import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_homework_form.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/routes/settings_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';

import '../hw_tile.dart';

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key, required this.title});

  static HomeRouteState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeRouteState>();

  final String title;

  @override
  State<HomeRoute> createState() => HomeRouteState();
}

class HomeRouteState extends State<HomeRoute> {
  late DBHelper dbHelper;

  final List<Homework> entries = List<Homework>.empty(growable: true);

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
                            title: 'Edit homework',
                            submit: 'Edit',
                            cancel: 'Cancel',
                          ),
                        ).then((v) {
                          if (v ?? false) setState(() {});
                        })));
          } else {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  CircularProgressIndicator(),
                  Text('Loading Database...\nMaybe check logs?')
                ]));
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
    if (kDebugMode) {
      print("REBUILD");
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsRoute()),
                    ))
          ]),
      body: hwListWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog(
          context: context,
          builder: (context) => const HomeworkFormDialog(
            title: 'Add homework',
            submit: 'Add',
            cancel: 'Cancel',
          ),
        ).then((v) {
          if (v) setState(() {});
        }),
        tooltip: 'Add homework',
        child: const Icon(Icons.add),
      ),
    );
  }
}
