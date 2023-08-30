import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart';

class CustomListItem extends StatelessWidget {
  const CustomListItem(
      {super.key, required this.thumbnail, required this.homework});

  final Widget thumbnail;
  final Homework homework;

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
                          onPressed: () {}, icon: const Icon(Icons.edit)),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_rounded)),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Text(DateFormat("EEEE, dd. MMMM, yyyy")
                      .format(homework.overdueTimestamp.toLocal())),
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
          SelectionArea(
            child: ExpandableText(
              homework.content,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.inverseSurface),
            ),
          ),
        ]);
  }
}

// TODO Use the following function to determine text overflow:
/*
bool hasTextOverflow(
  String text,
  TextStyle style,
  {double minWidth = 0,
       double maxWidth = double.infinity,
       int maxLines = 2
  }) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: minWidth, maxWidth: maxWidth);
  return textPainter.didExceedMaxLines;
}
 */
class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text,
      {super.key, this.style, this.overflow, textShowMore, treshold})
      : textShowMore = textShowMore ?? "...",
        treshold = treshold ?? 70;

  //text is the total text of our expandable widget
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final String textShowMore;
  final int treshold;

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late String textToDisplay;

  @override
  void initState() {
    //if the text has more than a certain number of characters, the text we display will consist of that number of characters;
    //if it's not longer we display all the text
    print(widget.text.length);

    //we arbitrarily chose 25 as the length
    textToDisplay = widget.text.length > widget.treshold
        ? widget.text.substring(0, widget.treshold) + widget.textShowMore
        : widget.text;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(
        textToDisplay,
        style: widget.style,
        overflow: widget.overflow,
      ),
      onTap: () {
        //if the text is not expanded we show it all
        if (widget.text.length > widget.treshold &&
            textToDisplay.length <=
                widget.treshold + widget.textShowMore.length) {
          setState(() {
            textToDisplay = widget.text;
          });
        }
        //else if the text is already expanded we contract it back
        else if (widget.text.length > widget.treshold &&
            textToDisplay.length > widget.treshold) {
          setState(() {
            textToDisplay =
                widget.text.substring(0, widget.treshold) + widget.textShowMore;
          });
        }
      },
    );
  }
}
