import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class DeleteFormDialog extends StatefulWidget {
  final Homework hw;

  const DeleteFormDialog(this.hw, {super.key});

  @override
  State<DeleteFormDialog> createState() => _DeleteFormDialogState();
}

class _DeleteFormDialogState extends State<DeleteFormDialog> {
  final List<int> _tempSelectedPages = [];
  int pages = 1;

  @override
  void initState() {
    super.initState();
    DBHelper.countHWPages(widget.hw.id ?? -1).then((value) => setState(() => pages = value));
  }

  Future<void> _deletePages(BuildContext context) async {
    if (kDebugMode) {
      print(_tempSelectedPages);
    }
    DBHelper.deleteHWPagesByHWOrder(widget.hw, _tempSelectedPages).then((value) {
      if (pages - _tempSelectedPages.length > 0) {
        return Navigator.pop(context, pages - _tempSelectedPages.length);
      }
      Navigator.popUntil(context, (route) => route.settings.name == "/");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // TITLE HERE
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0),
                        child: DefaultTextStyle(
                          style: DialogTheme.of(context).titleTextStyle ?? Theme.of(context).textTheme.titleLarge!,
                          textAlign: TextAlign.center,
                          child: Semantics(
                            // For iOS platform, the focus always lands on the title.
                            // Set nameRoute to false to avoid title being announce twice.
                            namesRoute: true,
                            container: true,
                            child: Text(context.locals.deletePagesTitle),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // CONTENT STARTING HERE
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 16.0, right: 24.0, bottom: 24.0),
                    child: DefaultTextStyle(
                      style: DialogTheme.of(context).contentTextStyle ?? Theme.of(context).textTheme.bodyMedium!,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pages,
                        itemBuilder: (BuildContext context, int index) => CheckboxListTile(
                          title: Text(context.locals.deletePagesEntry(index + 1)),
                          value: _tempSelectedPages.contains(index),
                          onChanged: (bool? value) {
                            if (value ?? true) {
                              if (_tempSelectedPages.contains(index)) return;
                              setState(() => _tempSelectedPages.add(index));
                            } else {
                              if (!_tempSelectedPages.contains(index)) return;
                              setState(() => _tempSelectedPages.removeWhere((i) => i == index));
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ACTIONS STARTING HERE
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, pages),
                  child: Text(context.locals.deletePagesCancel),
                ),
                ElevatedButton(
                  onPressed: () => _deletePages(context),
                  child: Text(context.locals.deletePagesTitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
