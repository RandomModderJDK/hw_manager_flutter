import 'package:date_field/date_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart';

class HomeworkFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;
  final Homework? homework;

  const HomeworkFormDialog(
      {super.key,
      required this.title,
      required this.submit,
      required this.cancel,
      this.homework});

  @override
  State<HomeworkFormDialog> createState() => _HomeworkFormDialogState();
}

class _HomeworkFormDialogState extends State<HomeworkFormDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DateTime _dateSelected = DateTime.now();
  bool _userDated = false;

  String subjectErrorText = "";

  @override
  void initState() {
    _initStateAsync();
    super.initState();
  }

  Future<void> _initStateAsync() async {
    if (widget.homework == null) return;
    _contentController.text = widget.homework!.content;
    _subjectController.text = widget.homework!.subject.name;
    _dateSelected = widget.homework!.overdueTimestamp;
    _userDated = true;
    //TODO REIMPLEMENT
    /*bool persisting = await Preferences.getDialogPersistence();
    if (!persisting) {
      setState(() {
        _dateSelected = DateTime.now();
        _userDated = false;
      });
    }*/
  }

  void _saveHomework(BuildContext context) async {
    String content = _contentController.text.trim();
    String subject = _subjectController.text.trim();

    Homework hw = Homework(
        id: widget.homework?.id,
        subject: Subject(name: subject),
        overdueTimestamp: _dateSelected,
        creationTimestamp: DateTime.timestamp(),
        content: content,
        finished: false);
    if (kDebugMode) {
      print(hw);
    }

    DBHelper().insertHomework(hw).then((value) => Navigator.pop(context, true));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      backgroundColor: Theme.of(context).colorScheme.background,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
          onPressed: () {
            if (_subjectController.text.isEmpty) {
              setState(() => subjectErrorText = "Enter Subject!");
            }
            if (!formKey.currentState!.validate()) return;
            if (_subjectController.text.isEmpty) return;
            _saveHomework(context);
          },
          child: Text(widget.submit),
        ),
      ],
      content: HomeworkFormContent(
          formKey: formKey,
          contentController: _contentController,
          subjectController: _subjectController,
          subjectErrorText: subjectErrorText,
          dateSelected: _dateSelected,
          userDated: _userDated,
          onDateSelected: (DateTime value) {
            setState(() {
              _dateSelected = value;
              _userDated = true;
            });
          }),
    );
  }
}

class HomeworkFormContent extends StatelessWidget {
  const HomeworkFormContent(
      {Key? key,
      required this.formKey,
      required this.contentController,
      required this.subjectController,
      required this.subjectErrorText,
      required this.dateSelected,
      required this.userDated,
      required this.onDateSelected})
      : super(key: key);

  final TextEditingController contentController;
  final TextEditingController subjectController;
  final String subjectErrorText;
  final DateTime dateSelected;
  final bool userDated;
  final Function(DateTime) onDateSelected;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DateTimeField(
            onDateSelected: onDateSelected,
            selectedDate: dateSelected,
            mode: DateTimeFieldPickerMode.date,
            decoration: const InputDecoration(
              labelText: "Until the",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(),
            ),
            initialDate: DateTime(2023, 8),
            dateFormat: DateFormat("dd. MMMM, yyyy"),
            use24hFormat: true,
          ),
          const SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.max, children: [
            Expanded(
                child: FutureBuilder(
                    future: DBHelper().retrieveSubjects(),
                    builder: (context, snapshot) => DropdownMenu(
                        controller: subjectController,
                        onSelected: (v) {},
                        // TODO Implement untis date fetching here. NOTE: Check for user date selection
                        enableSearch: true,
                        errorText: subjectErrorText,
                        requestFocusOnTap: true,
                        label: const Text("Subject"),
                        inputDecorationTheme: const InputDecorationTheme(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: OutlineInputBorder(),
                        ),
                        dropdownMenuEntries: snapshot.data != null
                            ? snapshot.data!
                                .map((s) => DropdownMenuEntry(
                                    value: s.name, label: s.name))
                                .toList()
                            : [])))
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: contentController,
            validator: (value) =>
                value!.isEmpty ? "Enter homework content!" : null,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: "Content",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
              hintText:
                  "What did you do last lesson?\nWhat could the teacher have been thinking?",
            ),
          ),
        ],
      ),
    );
  }
}
