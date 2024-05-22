import 'dart:async';

import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/discord_util.dart';
import 'package:hw_manager_flutter/general_util.dart';
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
      return context.locals.datePassed(date, date, date.hour);
    }
    switch (diff.inDays) {
      case 0:
        return context.locals.dateToday(date, date.hour);
      case 1:
        return context.locals.dateTomorrow(date, date.hour);
    }
    if (diff.inDays == 0) {}
    if (diff.inDays == 1) {}
    if (diff.inDays < 6) {
      return context.locals.dateThisWeek(date, date, date.hour);
    }
    if (diff.inDays >= 6 && diff.inDays < 13) {
      return context.locals.dateNextWeek(date, date, date.hour);
    }

    return context.locals.dateAnywhereElse(date, date, date, date.hour);
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
                Expanded(child: _HomeworkDescription(homework)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (homework.subject.discordChannel?.webhookUrl != null &&
                            homework.subject.discordChannel?.webhookUrl != "")
                          _HomeworkSendButton(homework: homework),
                        IconButton(
                          onPressed: () => onEdit(),
                          tooltip: context.locals.dialogHWEditTitle,
                          icon: const Icon(Icons.edit),
                        ),
                        StatefulBuilder(
                          builder: (context, setState) {
                            if (hasPhotos == null) {
                              return FutureBuilder(
                                future: DBHelper.countHWPages(homework.id ?? -1),
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
                                          tooltip: context.locals.openImageViewer,
                                          icon: const Icon(Icons.photo_album),
                                        )
                                      : IconButton(
                                          onPressed: () {
                                            pickAndAddImage(context, homework).then((success) {
                                              if (success) {
                                                setState(() {});
                                              }
                                            });
                                          },
                                          tooltip: context.locals.takePhoto,
                                          icon: const Icon(
                                            Icons.add_a_photo_rounded,
                                          ),
                                        );
                                },
                              );
                            } else {
                              DBHelper.countHWPages(homework.id ?? -1).then((value) {
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
                                    tooltip: context.locals.openImageViewer,
                                    icon: const Icon(Icons.photo_album),
                                  )
                                : IconButton(
                                    onPressed: () {
                                      pickAndAddImage(context, homework).then((success) {
                                        if (success) setState(() {});
                                      });
                                    },
                                    tooltip: context.locals.takePhoto,
                                    icon: const Icon(Icons.add_a_photo_rounded),
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

class _HomeworkSendButton extends StatefulWidget {
  final Homework homework;

  const _HomeworkSendButton({required this.homework});

  @override
  State<StatefulWidget> createState() => _HomeworkSendButtonState();
}

class _HomeworkSendButtonState extends State<_HomeworkSendButton> {
  // State 0 is not used, state 1 is delivery, state 2 is success, state 3 failure
  int state = 0;

  Timer? timer;

  @override
  Widget build(BuildContext context) {
    bool isDisabled = false;
    Widget? icon;

    switch (state) {
      case 0:
        icon = RotatedBox(
          quarterTurns: 3,
          child: widget.homework.messageID == null || widget.homework.messageID!.isEmpty
              ? const Icon(Icons.send_rounded)
              : const Icon(Icons.send_and_archive_rounded),
        );

      case 1: // On it's way
        isDisabled = true;
        timer = Timer(
          const Duration(seconds: 15),
          () => context.mounted ? setState(() => isDisabled = false) : null,
        );
        icon = const Icon(Icons.delivery_dining_outlined);
      case 2: // Success
        timer = Timer(
          const Duration(seconds: 2),
          () => context.mounted ? setState(() => state = 0) : null,
        );
        icon = const Icon(Icons.check_outlined);
      case 3: // Failure
        timer = Timer(
          const Duration(seconds: 2),
          () => context.mounted ? setState(() => state = 0) : null,
        );
        icon = const Icon(Icons.error_outline_outlined);
    }

    return IconButton(
      onPressed: isDisabled
          ? null
          : () {
              timer?.cancel(); // Cancel any pending displaying task
              final String url = widget.homework.subject.discordChannel!.webhookUrl!;
              DiscordHelper().sendWebhook(url, widget.homework).then(
                (v) => setState(() => state = v ? 2 : 3),
                onError: (obj, trace) {
                  discordError("$obj");
                  setState(() => state = 3);
                },
              );
              setState(() => state = 1);
            },
      tooltip: widget.homework.messageID == null || widget.homework.messageID!.isEmpty
          ? locals.discordCreateMessageButton
          : locals.discordEditMessageButton,
      icon: icon ?? const Icon(Icons.error_outline_outlined),
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
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xfffbeff3)
                  : Theme.of(context).colorScheme.background,
              // I don't know how to achieve the matching color in white mode, temporary solution, until I find a proper one
              boxShadow: const [],
              animationDuration: const Duration(milliseconds: 1),
              helperTextList: [
                context.locals.showMore,
                context.locals.showLess,
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
                Expanded(child: _SubjectDescription(subject)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: context.locals.dialogSubjectEditTitle,
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
        SelectionArea(
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
        SelectionArea(
          child: Text(
            "${context.locals.dialogSubjectChannelName}: ${subject.discordChannel?.channelName == null || subject.discordChannel?.channelName == "" ? "-" : subject.discordChannel!.channelName}",
            maxLines: 2,
            style: TextStyle(
              overflow: TextOverflow.clip,
              fontSize: 14,
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class DiscordRelationListItem extends StatelessWidget {
  const DiscordRelationListItem({
    super.key,
    required this.dr,
    required this.onEdit,
    required this.onDeleted,
  });

  final DiscordRelation dr;
  final void Function() onEdit;
  final Function(DismissDirection) onDeleted;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(dr.channelID),
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
                Expanded(child: _DiscordRelationDescription(dr)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: context.locals.dialogSubjectEditTitle,
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

class _DiscordRelationDescription extends StatelessWidget {
  const _DiscordRelationDescription(this.dr);

  final DiscordRelation dr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SelectionArea(
          child: Text(
            dr.channelName,
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
              dr.webhookUrl ?? "",
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
