import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_discordrelation_form.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/list_tiles.dart';
import 'package:hw_manager_flutter/my_listview.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class DiscordRoute extends StatefulWidget {
  const DiscordRoute({super.key});

  @override
  State<StatefulWidget> createState() => _DiscordRouteState();
}

class _DiscordRouteState extends State<DiscordRoute> {
  Widget? discordRelationList() {
    return FutureBuilder(
      future: DBHelper.retrieveDiscordRelations(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FloatingButtonCardListView(
            itemCount: snapshot.data!.length,
            child: (position) => DiscordRelationListItem(
              dr: snapshot.data![position],
              onEdit: () async => showDialog<bool>(
                context: context,
                builder: (context) => DiscordRelationFormDialog(
                  dr: snapshot.data![position],
                  title: context.locals.dialogDiscordRelationEditTitle,
                  submit: context.locals.dialogDiscordRelationEdit,
                  cancel: context.locals.dialogDiscordRelationEditCancel,
                ),
              ).then((bool? v) {
                if (v == true) setState(() {});
              }),
              onDeleted: (DismissDirection direction) async {
                final DiscordRelation dr = snapshot.data![position];
                snapshot.data!.remove(dr);
                await DBHelper.deleteDiscordRelation(dr.channelName);
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.locals.deleteDiscordRelationToast(dr.channelName, dr.webhookUrl ?? "-")),
                      action: SnackBarAction(
                        label: context.locals.deleteDiscordRelationToastUndo,
                        onPressed: () => DBHelper.insertDiscordRelation(dr).then((value) => setState(() {})),
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
        title: Text(context.locals.discordRelationsTitle),
      ),
      body: discordRelationList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => showDialog<bool>(
          context: context,
          builder: (context) => DiscordRelationFormDialog(
            title: context.locals.dialogDiscordRelationAddTitle,
            submit: context.locals.dialogDiscordRelationAdd,
            cancel: context.locals.dialogDiscordRelationAddCancel,
          ),
        ).then((bool? v) {
          if (v == true) setState(() {});
        }),
        tooltip: context.locals.dialogDiscordRelationAddTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
