import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/my_listview.dart';

import '../dialogs/dialog_subject_form.dart';
import '../list_tiles.dart';
import '../sqlite.dart';

class SubjectRoute extends StatefulWidget {
  const SubjectRoute({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubjectRouteState();
}

class _SubjectRouteState extends State<SubjectRoute> {
  late DBHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    // No need for db initialization, because home route loads inits it
    /*dbHelper.initDBs().whenComplete(() async {
      setState(() {});
    });*/
  }

  Widget? subjectList() {
    return FutureBuilder(
        future: dbHelper.retrieveSubjects(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FloatingButtonCardListView(
                itemCount: snapshot.data!.length,
                child: (position) => SubjectListItem(
                    subject: snapshot.data![position],
                    onEdit: () async => showDialog(
                          context: context,
                          builder: (context) => SubjectFormDialog(
                            subject: snapshot.data![position],
                            title: 'Edit subject',
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
                  Text('Loading database...\nMaybe check logs?')
                ]));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Settings')),
      body: subjectList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog(
          context: context,
          builder: (context) => const SubjectFormDialog(
            title: 'Add subject',
            submit: 'Add',
            cancel: 'Cancel',
          ),
        ).then((v) {
          if (v ?? false) setState(() {});
        }),
        tooltip: 'Add subject',
        child: const Icon(Icons.add),
      ),
    );
  }
}
