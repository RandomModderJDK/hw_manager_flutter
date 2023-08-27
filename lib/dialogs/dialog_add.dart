import 'package:date_field/date_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/intl.dart';

TextEditingController _contentController = TextEditingController();
TextEditingController _subjectController = TextEditingController();
DateTime _dateSelected = DateTime.now();
bool _userDated = false;

final List<DropdownMenuEntry> subjectEntries =
    List<DropdownMenuEntry>.empty(growable: true);

void _saveHomework(
    BuildContext context,
    void Function(VoidCallback fn) setState,
    DateTime dateSelected,
    bool userDated) {
  String content = _contentController.text;
  String subject = _subjectController.text;

  Homework hw = Homework(
      subject: Subject(name: subject),
      overdueTimestamp: dateSelected,
      creationTimestamp: DateTime.timestamp(),
      content: content,
      finished: false);
  if (kDebugMode) {
    print(hw);
  }
  DBHelper().insertHomework(hw).whenComplete(() => setState(() => ()));
  Navigator.pop(context);
}

// TODO implement saving action
// TODO add untis fetching to auto-select dates
void addHomework(
    BuildContext context, void Function(VoidCallback fn) setState) {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Load subject into dropdown selection
  DBHelper().retrieveSubjects().then((subjList) {
    subjectEntries.clear();
    subjectEntries.addAll(subjList
        .map((s) => DropdownMenuEntry(value: s.name, label: s.name))
        .toList());
  });

  Preferences.getDialogPersistence().then((persisting) {
    if (persisting) return; // Use fields from previous dialog
    _contentController = TextEditingController();
    _subjectController = TextEditingController();
    _dateSelected = DateTime.now();
    _userDated = false;
  });

  showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: const Text("Add Homework"),
              backgroundColor: Theme.of(context).colorScheme.background,
              actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900),
                    onPressed: () => Navigator.pop(context),
                    // Close dialog
                    child: const Text("Cancel")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900),
                    onPressed: () => {
                          if (formKey.currentState!.validate())
                            _saveHomework(
                                context, setState, _dateSelected, _userDated)
                        },
                    child: const Text("Ok")),
              ],
              //alignment: AlignmentDirectional.bottomCenter,
              content: Form(
                  key: formKey,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // TODO add date/time selection
                        DateTimeField(
                          onDateSelected: (DateTime value) => setState(() {
                            _dateSelected = value;
                            _userDated = true;
                          }),
                          selectedDate: _dateSelected,
                          mode: DateTimeFieldPickerMode.date,
                          decoration: const InputDecoration(
                              constraints: BoxConstraints(),
                              labelText: "Until the",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder()),
                          initialDate: DateTime(2023, 8),
                          dateFormat: DateFormat("dd. MMMM, yyyy"),
                        ),
                        const SizedBox(height: 12),
                        DropdownMenu(
                            controller: _subjectController,
                            enableSearch: true,
                            requestFocusOnTap: true,
                            label: const Text("Subject"),
                            inputDecorationTheme: const InputDecorationTheme(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder()),
                            dropdownMenuEntries: subjectEntries),
                        const SizedBox(height: 10),
                        TextFormField(
                            controller: _contentController,
                            validator: (value) => value!.isEmpty
                                ? "Enter homework content!"
                                : null,
                            maxLines: 5,
                            decoration: InputDecoration(
                                labelText: "Content",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: const OutlineInputBorder(),
                                hintStyle: TextStyle(
                                    color: Colors.grey.withOpacity(0.40)),
                                hintText:
                                    "What did you do last lesson?\nWhat could the teacher been thinking?")),
                      ])))));
}
