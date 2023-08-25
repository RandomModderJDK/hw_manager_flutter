import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/sqlite.dart';

// TODO implement saving action
// TODO add untis fetching to auto-select dates
void addHomework(BuildContext context) {
  TextEditingController _contentController = TextEditingController();
  TextEditingController _subjectController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  // TODO add time selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
    }
  }

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Homework"),
          backgroundColor: Theme.of(context).colorScheme.background,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  String content = _contentController.text;
                  String subject = _subjectController.text;

                  _selectDate(context).whenComplete(() {
                    Homework hw = Homework(
                        subject: Subject(name: subject),
                        overdueTimestamp: selectedDate,
                        creationTimestamp: DateTime.timestamp(),
                        content: content,
                        finished: false);
                    if (kDebugMode) {
                      print(hw);
                    }
                  });
                },
                child: const Text("Ok")),
            // TODO save homework
          ],
          content: Wrap(runSpacing: 10, children: <Widget>[
            // TODO add date/time selection
            DropdownMenu(
                controller: _subjectController,
                enableSearch: true,
                requestFocusOnTap: true,
                label: const Text("Subject"),
                inputDecorationTheme: const InputDecorationTheme(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder()),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: "Wert", label: "Label"),
                  DropdownMenuEntry(value: "Wert", label: "Label2"),
                  DropdownMenuEntry(value: "Wert", label: "Label3"),
                  DropdownMenuEntry(value: "Wert", label: "Label4")
                ]),
            TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                    labelText: "Content",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
                    hintText:
                        "What did you do last lesson?\nWhat could the teacher been thinking?")),
          ]),
        );
      });
}
