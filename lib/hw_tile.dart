import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart' as intl;

class HWListItem extends StatelessWidget {
  const HWListItem({super.key, required this.homework, required this.onEdit});

  final Homework homework;
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

String _formatDate(DateTime date) {
  Duration diff = date.difference(DateTime.now());
  print(diff.inDays);

  if (diff.inDays == 0) return "Today!"; // Diff of 0 is apparently negative
  if (diff.isNegative) return "Passed already";
  if (diff.inDays < 6) return "This ${intl.DateFormat("EEEE").format(date)}";
  if (diff.inDays >= 6 && diff.inDays < 13) {
    return "${intl.DateFormat("EEEE").format(date)}, next week";
  }

  return intl.DateFormat("EEEE, dd.MM.yyyy").format(date);
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
          SelectionArea(
            child: ExpandableText(
              homework.content,
              overflow: TextOverflow.clip,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.inverseSurface),
            ),
          ),
        ]);
  }
}

class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text,
      {super.key,
      required this.style,
      this.overflow,
      overflowText,
      treshold,
      maxLines})
      : overflowText = overflowText ?? "...",
        treshold = treshold ?? 70,
        maxLines = maxLines ?? 2;

  //text is the total text of our expandable widget
  final String text;
  final TextStyle style;
  final TextOverflow? overflow;
  final String overflowText;
  final int treshold;
  final int maxLines;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late String textToDisplay;
  bool contracted = true;

  @override
  void initState() {
    super.initState();
  }

  _formatText() {
    if (contracted) {
      textToDisplay = widget.text.length > widget.treshold
          ? widget.text.substring(0, widget.treshold) + widget.overflowText
          : widget.text;
    } else {
      textToDisplay = widget.text;
    }
  }

  bool _hasTextOverflow(String text,
      {double minWidth = 0, double maxWidth = double.infinity}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    _formatText();
    return InkWell(
      child: Text(
        textToDisplay,
        style: widget.style,
        overflow: widget.overflow,
        softWrap: true,
      ),
      onTap: () {
        //if the text is not expanded we show it all
        if (widget.text.length > widget.treshold &&
            textToDisplay.length <=
                widget.treshold + widget.overflowText.length) {
          contracted = false;
          setState(() {
            _formatText();
          });
        }
        //else if the text is already expanded we contract it back
        else if (widget.text.length > widget.treshold &&
            textToDisplay.length > widget.treshold) {
          contracted = true;
          setState(() {
            _formatText();
          });
        }
      },
    );
  }
}
