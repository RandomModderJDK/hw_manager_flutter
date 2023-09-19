import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hw_manager_flutter/routes/image_viewer_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class HWListItem extends StatelessWidget {
  const HWListItem({
    super.key,
    required this.homework,
    required this.onEdit,
    required this.onDeleted,
  });

  final Homework homework;
  final void Function() onEdit;
  final Function(DismissDirection) onDeleted;

  DateTime _dateTimeToDate(DateTime dateTime) => dateTime.copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

  String _formatDate(BuildContext context, DateTime date) {
    final Duration diff = _dateTimeToDate(date).difference(_dateTimeToDate(DateTime.now()));
    Duration diffWithTime = date.difference(DateTime.now());
    if (_dateTimeToDate(date).hour == 0) diffWithTime = diff;

    if (diffWithTime.isNegative || diffWithTime == Duration.zero) {
      return AppLocalizations.of(context)!.datePassed(date, date, date.hour);
    }
    if (diff.inDays == 0) {
      return AppLocalizations.of(context)!.dateToday(date, date.hour);
    }
    if (diff.inDays == 1) {
      return AppLocalizations.of(context)!.dateTomorrow(date, date.hour);
    }
    if (diff.inDays < 6) {
      return AppLocalizations.of(context)!.dateThisWeek(date, date, date.hour);
    }
    if (diff.inDays >= 6 && diff.inDays < 13) {
      return AppLocalizations.of(context)!.dateNextWeek(date, date, date.hour);
    }

    return AppLocalizations.of(context)!.dateAnywhereElse(date, date, date, date.hour);
  }

  @override
  Widget build(BuildContext context) {
    bool? hasPhotos;
    return Dismissible(
      key: Key(homework.id!.toString()),
      onDismissed: onDeleted,
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.all(30),
        child: const Icon(Icons.delete_rounded),
      ),
      background: Container(
        alignment: Alignment.centerLeft,
        color: Colors.red,
        padding: const EdgeInsets.all(30),
        child: const Icon(Icons.delete_rounded),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
        shape: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.5,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: _HomeworkDescription(homework),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => onEdit(),
                          tooltip: AppLocalizations.of(context)!.dialogHWEditTitle,
                          icon: const Icon(Icons.edit),
                        ),
                        StatefulBuilder(
                          builder: (context, setState) {
                            if (hasPhotos == null) {
                              return FutureBuilder(
                                future: DBHelper().countHWPages(homework.id ?? -1),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    hasPhotos = snapshot.data! > 0;
                                  } else {
                                    return const CircularProgressIndicator();
                                  }
                                  return hasPhotos!
                                      ? IconButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ImageViewerRoute(
                                                homework: homework,
                                              ),
                                            ),
                                          ).then((value) => setState(() {})),
                                          tooltip: AppLocalizations.of(context)!.openImageViewer,
                                          icon: const Icon(Icons.photo_album),
                                        )
                                      : IconButton(
                                          onPressed: () {
                                            pickAndAddImage(
                                              context,
                                              homework,
                                            ).then((success) {
                                              if (success) {
                                                setState(() {});
                                              }
                                            });
                                          },
                                          tooltip: AppLocalizations.of(context)!.takePhoto,
                                          icon: const Icon(
                                            Icons.add_a_photo_rounded,
                                          ),
                                        );
                                },
                              );
                            } else {
                              DBHelper().countHWPages(homework.id ?? -1).then((value) {
                                if (hasPhotos == value > 0) return;
                                setState(() => hasPhotos = value > 0);
                              });
                            }

                            return hasPhotos!
                                ? IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageViewerRoute(
                                          homework: homework,
                                        ),
                                      ),
                                    ).then((value) => setState(() {})),
                                    tooltip: AppLocalizations.of(context)!.openImageViewer,
                                    icon: const Icon(Icons.photo_album),
                                  )
                                : IconButton(
                                    onPressed: () {
                                      pickAndAddImage(context, homework).then((success) {
                                        if (success) setState(() {});
                                      });
                                    },
                                    tooltip: AppLocalizations.of(context)!.takePhoto,
                                    icon: const Icon(
                                      Icons.add_a_photo_rounded,
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(
                        context,
                        homework.overdueTimestamp.toLocal(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeworkDescription extends StatelessWidget {
  const _HomeworkDescription(this.homework);

  final Homework homework;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SelectionArea(
          child: Text(
            homework.subject.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 0.8)),
        Expanded(
          child: SelectionArea(
            child: ExpandableText(
              backgroundColor: Theme.of(context).colorScheme.surface,
              boxShadow: const [],
              animationDuration: const Duration(milliseconds: 1),
              helperTextList: [
                AppLocalizations.of(context)!.showMore,
                AppLocalizations.of(context)!.showLess,
              ],
              padding: EdgeInsets.zero,
              helper: Helper.text,
              helperTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textWidget: Text(
                homework.content,
                maxLines: 2,
                style: TextStyle(
                  overflow: TextOverflow.fade,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SubjectListItem extends StatelessWidget {
  const SubjectListItem({
    super.key,
    required this.subject,
    required this.onEdit,
    required this.onDeleted,
  });

  final Subject subject;
  final void Function() onEdit;
  final Function(DismissDirection) onDeleted;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(subject.name),
      onDismissed: onDeleted,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(30),
        child: const Icon(Icons.delete_forever),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
        shape: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.5,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: _SubjectDescription(subject),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.dialogSubjectEditTitle,
                      onPressed: () => onEdit(),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectDescription extends StatelessWidget {
  const _SubjectDescription(this.subject);

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SelectionArea(
          child: Text(
            subject.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 0.8)),
        Expanded(
          child: SelectionArea(
            child: Text(
              subject.shortName ?? "",
              maxLines: 2,
              style: TextStyle(
                overflow: TextOverflow.clip,
                fontSize: 14,
                color: Theme.of(context).colorScheme.inverseSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
