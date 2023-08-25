import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_add.dart';
import 'package:hw_manager_flutter/routes/settings_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key, required this.title});

  final String title;

  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  late DBHelper dbHelper;

  final List<String> entries = <String>['A', 'B', 'C'];
  final List<int> colorCodes = <int>[600, 500, 100];
  bool dbLoaded = false;

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    dbHelper.initDBs().whenComplete(() async {
      setState(() => dbLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: dbLoaded
          ? ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 50,
                  color: Colors.amber[colorCodes[index]],
                  child: Text('Entry ${entries[index]}\nTest'),
                );
              })
          : const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  Text('Loading Database...\nMaybe check logs?')
                ])),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addHomework(context),
        tooltip: 'Add homework',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
