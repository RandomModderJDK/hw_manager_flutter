import 'package:expandable_widgets/expandable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart' as intl;

class HWListItem extends StatelessWidget {
  const HWListItem({super.key, required this.homework, required this.onEdit});

  final Homework homework;
  final Function onEdit;

  String _formatDate(DateTime date) {
    Duration diff = date.difference(DateTime.now());

    if (diff.inDays == 0) return "Today!"; // Diff of 0 is apparently negative
    if (diff.isNegative) return "Passed already";
    if (diff.inDays < 6) return "This ${intl.DateFormat("EEEE").format(date)}";
    if (diff.inDays >= 6 && diff.inDays < 13) {
      return "${intl.DateFormat("EEEE").format(date)}, next week";
    }

    return intl.DateFormat("EEEE, dd.MM.yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                  const Spacer(flex: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () => onEdit(),
                          icon: const Icon(Icons.edit)),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_rounded)),
                      // TODO Implement Photo view/taking
                    ],
                  ),
                  const Spacer(flex: 1),
                  Text(_formatDate(homework.overdueTimestamp.toLocal())),
                ],
              ),
            ]),
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
              child: Text(homework.subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary))),
          const Padding(padding: EdgeInsets.only(bottom: 0.8)),
          Expanded(
            child: SelectionArea(
              child: ExpandableText(
                backgroundColor: Theme.of(context).colorScheme.surface,
                boxShadow: const [],
                animationDuration: const Duration(milliseconds: 1),
                helperTextList: const [" Show more", " Show less"],
                padding: EdgeInsets.zero,
                helper: Helper.text,
                helperTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
                textWidget: Text(
                  homework.content,
                  maxLines: 2,
                  style: TextStyle(
                      overflow: TextOverflow.clip,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
              ),
            ),
          ),
        ]);
  }
}

class SubjectListItem extends StatelessWidget {
  const SubjectListItem(
      {super.key, required this.subject, required this.onEdit});

  final Subject subject;
  final Function onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      onPressed: () => onEdit(), icon: const Icon(Icons.edit))
                ],
              ),
            ]),
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
              child: Text(subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary))),
          const Padding(padding: EdgeInsets.only(bottom: 0.8)),
          Expanded(
            child: SelectionArea(
                child: Text(
              subject.shortName ?? "",
              maxLines: 2,
              style: TextStyle(
                  overflow: TextOverflow.clip,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.inverseSurface),
            )),
          ),
        ]);
  }
}