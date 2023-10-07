import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hw_manager_flutter/dialogs/dialog_subject_form.dart';
import 'package:hw_manager_flutter/list_tiles.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class SynchronizeRoute extends StatefulWidget {
  const SynchronizeRoute({super.key});

  @override
  State<StatefulWidget> createState() => _SynchronizeRouteState();
}

class _SynchronizeRouteState extends State<SynchronizeRoute> {
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
              onEdit: () async => showDialog<bool>(
                context: context,
                builder: (context) => SubjectFormDialog(
                  subject: snapshot.data![position],
                  title: AppLocalizations.of(context)!.dialogSubjectEditTitle,
                  submit: AppLocalizations.of(context)!.dialogSubjectEdit,
                  cancel: AppLocalizations.of(context)!.dialogSubjectEditCancel,
                ),
              ).then((bool? v) {
                if (v == true) setState(() {});
              }),
              onDeleted: (DismissDirection direction) async {
                final Subject subject = snapshot.data![position];
                snapshot.data!.remove(subject);
                await DBHelper().deleteSubject(subject.name);
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.deleteSubjectToast(
                            subject.name, subject.shortName ?? "-"),
                      ),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!
                            .deleteSubjectToastUndo,
                        onPressed: () => DBHelper()
                            .insertSubject(subject)
                            .then((value) => setState(() {})),
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
                Text('Loading database...\nMaybe check logs?'),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.subjectsTitle),
      ),
      body: subjectList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog<bool>(
          context: context,
          builder: (context) => SubjectFormDialog(
            title: AppLocalizations.of(context)!.dialogSubjectAddTitle,
            submit: AppLocalizations.of(context)!.dialogSubjectAdd,
            cancel: AppLocalizations.of(context)!.dialogSubjectAddCancel,
          ),
        ).then((bool? v) {
          if (v == true) setState(() {});
        }),
        tooltip: AppLocalizations.of(context)!.dialogSubjectAddTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
