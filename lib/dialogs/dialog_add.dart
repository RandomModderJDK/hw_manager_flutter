import 'package:flutter/material.dart';

// TODO implement saving action
void addHomework(BuildContext context) {
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
            ElevatedButton(onPressed: () {}, child: const Text("Ok")),
            // TODO save homework
          ],
          content: Wrap(children: <Widget>[
            // TODO add subject and date selection
            TextField(
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
