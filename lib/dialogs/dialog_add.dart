import 'package:date_field/date_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart';

class HomeworkFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;

  const HomeworkFormDialog(
      {super.key,
      required this.title,
      required this.submit,
      required this.cancel});

  @override
  _HomeworkFormDialogState createState() => _HomeworkFormDialogState();
}

class _HomeworkFormDialogState extends State<HomeworkFormDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DateTime _dateSelected = DateTime.now();
  bool _userDated = false;
  final List<DropdownMenuEntry> subjectEntries = [];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    bool persisting = await Preferences.getDialogPersistence();
    if (!persisting) {
      setState(() {
        _dateSelected = DateTime.now();
        _userDated = false;
      });
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    List<Subject> subjList = await DBHelper().retrieveSubjects();
    setState(() {
      subjectEntries.clear();
      subjectEntries.addAll(subjList
          .map((s) => DropdownMenuEntry(value: s.name, label: s.name))
          .toList());
    });
  }

  void _saveHomework(BuildContext context) {
    String content = _contentController.text;
    String subject = _subjectController.text;

    Homework hw = Homework(
        subject: Subject(name: subject),
        overdueTimestamp: _dateSelected,
        creationTimestamp: DateTime.timestamp(),
        content: content,
        finished: false);

    if (kDebugMode) {
      print(hw);
    }

    DBHelper().insertHomework(hw);
    Navigator.pop(context, true);
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
            if (formKey.currentState!.validate()) {
              _saveHomework(context);
            }
          },
          child: Text(widget.submit),
        ),
      ],
      content: HomeworkFormContent(
        formKey: formKey,
        contentController: _contentController,
        subjectController: _subjectController,
        dateSelected: _dateSelected,
        userDated: _userDated,
        onDateSelected: (DateTime value) {
          setState(() {
            _dateSelected = value;
            _userDated = true;
          });
        },
        subjectEntries: subjectEntries,
      ),
    );
  }
}

class HomeworkFormContent extends StatelessWidget {
  HomeworkFormContent({
    Key? key,
    required this.formKey,
    required this.contentController,
    required this.subjectController,
    required this.dateSelected,
    required this.userDated,
    required this.onDateSelected,
    required this.subjectEntries,
  }) : super(key: key);

  final TextEditingController contentController;
  final TextEditingController subjectController;
  final DateTime dateSelected;
  final bool userDated;
  final Function(DateTime) onDateSelected;
  final List<DropdownMenuEntry> subjectEntries;
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
            decoration: InputDecoration(
              labelText: "Until the",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(),
            ),
            initialDate: DateTime(2023, 8),
            dateFormat: DateFormat("dd. MMMM, yyyy"),
            use24hFormat: true,
          ),
          const SizedBox(height: 12),
          DropdownMenu(
            controller: subjectController,
            enableSearch: true,
            requestFocusOnTap: true,
            label: const Text("Subject"),
            inputDecorationTheme: const InputDecorationTheme(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(),
            ),
            dropdownMenuEntries: subjectEntries,
          ),
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
