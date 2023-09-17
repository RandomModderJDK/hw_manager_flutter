import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hw_manager_flutter/dialogs/dialog_delete_form.dart';

import '../dialogs/dialog_homework_form.dart';
import '../sqlite.dart';

class ImageViewerRoute extends StatefulWidget {
  final Homework homework;

  const ImageViewerRoute({Key? key, required this.homework}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageViewerRouteState();
}

class _ImageViewerRouteState extends State<ImageViewerRoute> {
  int page = 0;
  int pages = 1;

  @override
  void initState() {
    super.initState();
    page = 0;
    pages = 1;
    initTransCont();
  }

  final _controller = TransformationController();

  void initTransCont() {
    const zoomFactor = 1.0;
    const double xTranslate = 0;
    const double yTranslate = 0;
    _controller.value.setEntry(0, 0, zoomFactor);
    _controller.value.setEntry(1, 1, zoomFactor);
    _controller.value.setEntry(2, 2, zoomFactor);
    _controller.value.setEntry(3, 3, zoomFactor);
    _controller.value.setEntry(0, 3, -xTranslate);
    _controller.value.setEntry(1, 3, -yTranslate);
  }

  Widget? photoViewer() {
    return FutureBuilder(
      future: (() async => await DBHelper().retrieveHWPage(widget.homework, page))(),
      builder: (_, snap) {
        if (snap.hasData) {
          if (snap.data == null) {
            return const Text("There are no pages");
          }
          Image image = Image.memory(
            snap.data!.data,
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
          );
          DBHelper().countHWPages(widget.homework.id!).then((value) {
            if (value == pages) return;
            setState(() => pages = value);
          });
          if (kDebugMode) {
            print("PAGES: $pages, CURRENT: $page");
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 3),
              Align(
                child: Text(AppLocalizations.of(context)!.pageDisplay(page + 1, pages)),
              ),
              Expanded(
                child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 0.75,
                    maxScale: 50,
                    boundaryMargin: const EdgeInsets.symmetric(vertical: 200, horizontal: 700),
                    clipBehavior: Clip.none,
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: image)),
              ),
            ],
          );
        } else {
          return const LinearProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("initState $page $pages");
    }
    return FutureBuilder(
        future: DBHelper().countHWPages(widget.homework.id ?? -1),
        builder: (context, snap) {
          if (snap.hasData) if (snap.data! != 0) pages = snap.data!;
          return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                actions: [
                  IconButton(
                      onPressed: () => showDialog(
                            context: context,
                            builder: (context) => DeleteFormDialog(widget.homework),
                          ).then((value) {
                            if (value == null) return;
                            if (value == pages) return;
                            setState(() {
                              page = value - 1;
                              pages = value;
                            });
                          }),
                      tooltip: AppLocalizations.of(context)!.deletePagesTitle,
                      icon: const Icon(Icons.delete_rounded)),
                  IconButton(
                    onPressed: () {
                      pickAndAddImage(context, widget.homework).then((success) {
                        if (success) setState(() => pages++);
                      });
                    },
                    tooltip: AppLocalizations.of(context)!.takePhoto,
                    icon: const Icon(Icons.add_a_photo_rounded),
                  ),
                  IconButton(
                      icon: const Icon(Icons.reorder_rounded),
                      tooltip: AppLocalizations.of(context)!.dialogHWEditTitle,
                      onPressed: () => showDialog(
                            context: context,
                            builder: (context) => HomeworkFormDialog(
                              homework: widget.homework,
                              title: AppLocalizations.of(context)!.dialogHWEditTitle,
                              submit: AppLocalizations.of(context)!.dialogHWEdit,
                              cancel: AppLocalizations.of(context)!.dialogHWEditCancel,
                            ),
                          ).then((v) {
                            if (v ?? false) setState(() {});
                          })),
                ],
                title: Text(AppLocalizations.of(context)!.imageViewer)),
            body: photoViewer(),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (page != 0)
                FloatingActionButton(
                  onPressed: () => setState(() {
                    page--;
                    initTransCont();
                  }),
                  tooltip: AppLocalizations.of(context)!.previousPage,
                  child: const Icon(Icons.navigate_before_rounded),
                ),
              if (page != 0 || page + 1 != pages) const SizedBox(width: 3),
              if (page != pages - 1)
                FloatingActionButton(
                  onPressed: () => setState(() {
                    page++;
                    initTransCont();
                  }),
                  tooltip: AppLocalizations.of(context)!.nextPage,
                  child: const Icon(Icons.navigate_next_rounded),
                )
            ]),
          );
        });
  }
}
