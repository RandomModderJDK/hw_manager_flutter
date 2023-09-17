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

  bool get isFirstPage => page != 0;

  bool get isLastPage => page + 1 != pages;

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

  final List<Image> _images = [];

  Widget _refreshImages(BuildContext context) {
    if (kDebugMode) {
      print("REFRESH IMAGES");
    }
    return FutureBuilder(
      future: (() async => await DBHelper().retrieveHWPages(widget.homework))(),
      builder: (_, snap) {
        if (snap.hasData) {
          _images.clear();
          _images.addAll(snap.data!.map((e) => Image.memory(
                e.data,
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                gaplessPlayback: true,
              )));
          return _images[page];
        } else {
          return const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[CircularProgressIndicator(), Text('Loading images...')]));
        }
      },
    );
  }

  Widget? photoViewer() {
    if (kDebugMode) {
      print("PAGES: $pages, CURRENT: $page");
    }
    DBHelper().countHWPages(widget.homework.id!).then((value) {
      if (value == pages) return;
      setState(() => pages = value);
    });
    return Column(
      children: [
        const SizedBox(height: 3),
        Center(child: Text(AppLocalizations.of(context)!.pageDisplay(page + 1, pages))),
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
                  child: Builder(
                    builder: (context) {
                      if (_images.isEmpty) return _refreshImages(context);
                      return _images[page];
                    },
                  ))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("initState $page $pages");
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
                onPressed: () => showDialog(context: context, builder: (context) => DeleteFormDialog(widget.homework))
                    .then(_removePage),
                tooltip: AppLocalizations.of(context)!.deletePagesTitle,
                icon: const Icon(Icons.delete_rounded)),
            IconButton(
              onPressed: () => pickAndAddImage(context, widget.homework).then(_addPage),
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
                          cancel: AppLocalizations.of(context)!.dialogHWEditCancel),
                    )),
          ],
          title: Text(AppLocalizations.of(context)!.imageViewer)),
      body: photoViewer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isFirstPage)
          FloatingActionButton(
            onPressed: _previousPage,
            tooltip: AppLocalizations.of(context)!.previousPage,
            child: const Icon(Icons.navigate_before_rounded),
          ),
        if (isFirstPage || isLastPage) const SizedBox(width: 3),
        if (isLastPage)
          FloatingActionButton(
            onPressed: _nextPage,
            tooltip: AppLocalizations.of(context)!.nextPage,
            child: const Icon(Icons.navigate_next_rounded),
          )
      ]),
    );
  }

  void _nextPage() {
    setState(() {
      page++;
      initTransCont();
    });
  }

  void _previousPage() {
    setState(() {
      page--;
      initTransCont();
    });
  }

  void _addPage(success) {
    if (success != true) return;
    setState(() => pages++);
  }

  void _removePage(value) {
    if (value == null) return;
    if (value == pages) return;
    setState(() {
      if (page == value) page = value - 1;
      pages = value;
    });
  }
}
