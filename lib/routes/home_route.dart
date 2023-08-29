import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_add.dart';
import 'package:hw_manager_flutter/routes/settings_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart';

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
            return ListView.builder(
                itemCount: snapshot.data?.length,
                itemBuilder: (context, position) => Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                    shape: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1.5,
                            color:
                                Theme.of(context).colorScheme.inversePrimary),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0))),
                    child: ListTile(
                        minVerticalPadding: 10,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                        title: Text(snapshot.data![position].subject.name),
                        titleTextStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                        subtitle: Text(snapshot.data![position].content),
                        visualDensity: VisualDensity.comfortable,
                        trailing: Column(
                          children: [
                            Expanded(
                                child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.edit)),
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.camera_alt_rounded)),
                              ],
                            )),
                            Text(DateFormat("EEEE, dd. MMMM, yyyy").format(
                                snapshot.data![position].overdueTimestamp
                                    .toLocal())),
                          ],
                        )))); /*Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12.0, 12.0, 12.0, 6.0),
                                      child: Text(
                                        snapshot.data![position].subject.name,
                                        style: const TextStyle(
                                            fontSize: 22.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12.0, 6.0, 12.0, 12.0),
                                      child: Text(
                                        snapshot.data![position].content,
                                        style: TextStyle(fontSize: 18.0),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100)),
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Text(
                                                          DateFormat(
                                                                  "EEEE, dd. MMMM, yyyy")
                                                              .format(snapshot
                                                                  .data![
                                                                      position]
                                                                  .overdueTimestamp
                                                                  .toLocal()),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                          )))),
                                            ]))),
                              ],
                            ),
                            const Divider(
                              height: 2.0,
                              color: Colors.grey,
                            )
                          ],
                        ),*/
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
        onPressed: () async => addHomework(context, setState).then((v) {
          if (v) setState(() {});
        }),
        tooltip: 'Add homework',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
