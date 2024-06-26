import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_delete_form.dart';
import 'package:hw_manager_flutter/dialogs/dialog_homework_form.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class ImageViewerRoute extends StatefulWidget {
  final Homework homework;

  const ImageViewerRoute({super.key, required this.homework});

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
      future: (() async => DBHelper.retrieveHWPages(widget.homework))(),
      builder: (_, snap) {
        if (snap.hasData) {
          _images.clear();
          _images.addAll(
            snap.data!.map((e) => Image.memory(e.data, fit: BoxFit.scaleDown, gaplessPlayback: true)),
          );
          return _images[page];
        } else {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                Text('Loading images...'),
              ],
            ),
          );
        }
      },
    );
  }

  Widget? photoViewer() {
    if (kDebugMode) {
      print("PAGES: $pages, CURRENT: $page");
    }
    DBHelper.countHWPages(widget.homework.id!).then((value) {
      if (value == pages) return;
      setState(() => pages = value);
    });
    return Column(
      children: [
        const SizedBox(height: 3),
        Center(child: Text(context.locals.pageDisplay(page + 1, pages))),
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
                  if (page >= _images.length) return _refreshImages(context);
                  return _images[page];
                },
              ),
            ),
          ),
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
        backgroundColor: context.inversePrimaryColor,
        actions: [
          IconButton(
            onPressed: () => showDialog<int>(
              context: context,
              builder: (context) => DeleteFormDialog(widget.homework),
            ).then(_removePage),
            tooltip: context.locals.deletePagesTitle,
            icon: const Icon(Icons.delete_rounded),
          ),
          IconButton(
            onPressed: () => pickAndAddImage(context, widget.homework).then(_addPage),
            tooltip: context.locals.takePhoto,
            icon: const Icon(Icons.add_a_photo_rounded),
          ),
          IconButton(
            icon: const Icon(Icons.reorder_rounded),
            tooltip: context.locals.dialogHWEditTitle,
            onPressed: () => showDialog(
              context: context,
              builder: (context) => HomeworkFormDialog(
                homework: widget.homework,
                title: context.locals.dialogHWEditTitle,
                submit: context.locals.dialogHWEdit,
                cancel: context.locals.dialogHWEditCancel,
              ),
            ),
          ),
        ],
        title: Text(context.locals.imageViewer),
      ),
      body: photoViewer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFirstPage)
            FloatingActionButton(
              onPressed: _previousPage,
              tooltip: context.locals.previousPage,
              child: const Icon(Icons.navigate_before_rounded),
            ),
          if (isFirstPage || isLastPage) const SizedBox(width: 3),
          if (isLastPage)
            FloatingActionButton(
              onPressed: _nextPage,
              tooltip: context.locals.nextPage,
              child: const Icon(Icons.navigate_next_rounded),
            ),
        ],
      ),
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

  void _addPage(bool success) {
    if (success != true) return;
    setState(() => pages++);
  }

  void _removePage(int? value) {
    if (value == null) return;
    if (value == pages) return;
    setState(() {
      if (page == value) page = value - 1;
      pages = value;
    });
  }
}
