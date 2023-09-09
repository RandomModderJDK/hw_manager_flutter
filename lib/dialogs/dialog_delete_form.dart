import 'package:flutter/material.dart';

import '../sqlite.dart';

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
    DBHelper()
        .countHWPages(widget.hw.id ?? -1)
        .then((value) => setState(() => pages = value));
  }

  void _deletePages(BuildContext context) async {
    print(_tempSelectedPages);
    DBHelper()
        .deleteHWPagesByHWOrder(widget.hw, _tempSelectedPages)
        .then((value) {
      if (pages - _tempSelectedPages.length > 0) {
        return Navigator.pop(context, pages - _tempSelectedPages.length);
      }
      Navigator.popUntil(context, (route) => route.settings.name == "/");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                    // TITLE HERE
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 24.0,
                                top: 24.0,
                                right: 24.0,
                                bottom: 0.0),
                            child: DefaultTextStyle(
                              style: DialogTheme.of(context).titleTextStyle ??
                                  Theme.of(context).textTheme.titleLarge!,
                              textAlign: TextAlign.center,
                              child: Semantics(
                                // For iOS platform, the focus always lands on the title.
                                // Set nameRoute to false to avoid title being announce twice.
                                namesRoute: true,
                                container: true,
                                child: const Text("Delete pages"),
                              ),
                            ),
                          ),
                        ]),
                    // CONTENT STARTING HERE
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24.0, top: 16.0, right: 24.0, bottom: 24.0),
                      child: DefaultTextStyle(
                        style: DialogTheme.of(context).contentTextStyle ??
                            Theme.of(context).textTheme.bodyMedium!,
                        child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: pages,
                          itemBuilder: (BuildContext context, int index) {
                            final checkboxName = "Page ${index + 1}";
                            return CheckboxListTile(
                                title: Text(checkboxName),
                                value: _tempSelectedPages.contains(index),
                                onChanged: (bool? value) {
                                  if (value ?? true) {
                                    if (!_tempSelectedPages.contains(index)) {
                                      setState(() {
                                        _tempSelectedPages.add(index);
                                      });
                                    }
                                  } else {
                                    if (_tempSelectedPages.contains(index)) {
                                      setState(() {
                                        _tempSelectedPages
                                            .removeWhere((int i) => i == index);
                                      });
                                    }
                                  }
                                });
                          },
                        ),
                      ),
                    )
                  ]))),
          // ACTIONS STARTING HERE
          Padding(
              padding:
                  const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                overflowDirection: VerticalDirection.down,
                overflowSpacing: 0,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900),
                    onPressed: () => Navigator.pop(context, pages),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900),
                    onPressed: () => _deletePages(context),
                    child: const Text("Delete"),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
