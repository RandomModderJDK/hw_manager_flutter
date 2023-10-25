import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_subject_form.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/list_tiles.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class SynchronizeRoute extends StatefulWidget {
  const SynchronizeRoute({super.key});

  @override
  State<StatefulWidget> createState() => _SynchronizeRouteState();
}

class _SynchronizeRouteState extends State<SynchronizeRoute> {
  Widget? subjectList() {
    return FutureBuilder(
      future: DBHelper.retrieveSubjects(),
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
                  title: context.locals.dialogSubjectEditTitle,
                  submit: context.locals.dialogSubjectEdit,
                  cancel: context.locals.dialogSubjectEditCancel,
                ),
              ).then((bool? v) {
                if (v == true) setState(() {});
              }),
              onDeleted: (DismissDirection direction) async {
                final Subject subject = snapshot.data![position];
                snapshot.data!.remove(subject);
                await DBHelper.deleteSubject(subject.name);
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.locals.deleteSubjectToast(
                          subject.name,
                          subject.shortName ?? "-",
                        ),
                      ),
                      action: SnackBarAction(
                        label: context.locals.deleteSubjectToastUndo,
                        onPressed: () => DBHelper.insertSubject(subject).then((value) => setState(() {})),
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
        title: Text(context.locals.subjectsTitle),
      ),
      body: subjectList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog<bool>(
          context: context,
          builder: (context) => SubjectFormDialog(
            title: context.locals.dialogSubjectAddTitle,
            submit: context.locals.dialogSubjectAdd,
            cancel: context.locals.dialogSubjectAddCancel,
          ),
        ).then((bool? v) {
          if (v == true) setState(() {});
        }),
        tooltip: context.locals.dialogSubjectAddTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
