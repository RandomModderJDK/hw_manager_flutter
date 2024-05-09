import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:hw_manager_flutter/untis_util.dart';
import 'package:intl/intl.dart';

class HomeworkFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;
  final Homework? homework;

  const HomeworkFormDialog({
    super.key,
    required this.title,
    required this.submit,
    required this.cancel,
    this.homework,
  });

  @override
  State<HomeworkFormDialog> createState() => _HomeworkFormDialogState();
}

class _HomeworkFormDialogState extends State<HomeworkFormDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DateTime _dateSelected = DateTime.now();
  bool _userDated = false;

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
  }

  Future<void> _saveHomework(BuildContext context) async {
    final String content = _contentController.text.trim();
    final String subject = _subjectController.text.trim();

    final Homework hw = Homework(
      id: widget.homework?.id,
      subject: Subject(name: subject),
      overdueTimestamp: _dateSelected,
      creationTimestamp: DateTime.timestamp(),
      content: content,
      finished: false,
    );
    if (kDebugMode) {
      print(hw);
    }

    DBHelper.insertHomework(hw).then((value) => Navigator.pop(context, true));
  }

  @override
  Widget build(BuildContext context) {
    // TODO(RandomModderJDK): Add toggle option, so untis fetching on every letter can be enabled
    /*_subjectController.addListener(() async {
      final String subjectName = _subjectController.text;
      if (kDebugMode) {
        print("Subject text changed to: $subjectName");
      }
      final UntisSubject? subject = await UntisHelper().searchUntisSubject(subjectName);
      if (kDebugMode) {
        print("found this subject in untis: $subject");
      }
      if (subject == null) return;
      final UntisPeriod? period = await UntisHelper().searchUntisSubjectUntisPeriod(subject);
      if (kDebugMode) {
        print("and these periods: $period");
      }
      if (period == null) return;
      setState(() {
        _dateSelected = period.startDateTime;
      });
    });*/
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      backgroundColor: context.backgroundColor,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            _saveHomework(context);
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
        onSubjectSelected: (s) async {
          if (s == null) return;
          // Trigger the next date search from untis
          final UntisSubject? subject = await UntisHelper().searchUntisSubject(s.name, s.shortName);
          if (kDebugMode) {
            print("found this subject in untis: $subject");
          }
          if (subject == null) return;
          final UntisPeriod? period = await UntisHelper().searchUntisSubjectUntisPeriod(subject);
          if (kDebugMode) {
            print("and these periods: $period");
          }
          if (period == null) return;
          setState(() {
            _dateSelected = period.startDateTime;
          });
        },
      ),
    );
  }
}

class HomeworkFormContent extends StatelessWidget {
  const HomeworkFormContent({
    super.key,
    required this.formKey,
    required this.contentController,
    required this.subjectController,
    required this.dateSelected,
    required this.userDated,
    required this.onDateSelected,
    required this.onSubjectSelected,
  });

  final TextEditingController contentController;
  final TextEditingController subjectController;
  final DateTime dateSelected;
  final bool userDated;
  final Function(DateTime) onDateSelected;
  final void Function(Subject?) onSubjectSelected;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FutureBuilder(
            future: DBHelper.retrieveSubjects(),
            builder: (context, snapshot) {
              return FormField<String>(
                validator: (s) => s == null || s.isEmpty ? context.locals.dialogHWSubjectValidator : null,
                builder: (FormFieldState<String> field) {
                  subjectController.addListener(() => field.didChange(subjectController.text));
                  return DropdownMenu<Subject>(
                    errorText: field.hasError ? field.errorText : null,
                    menuHeight: 250,
                    requestFocusOnTap: true,
                    inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                    controller: subjectController,
                    onSelected: onSubjectSelected,
                    label: Text(context.locals.dialogHWSubject),
                    dropdownMenuEntries: snapshot.data != null
                        ? snapshot.data!.map((s) => DropdownMenuEntry(value: s, label: s.name)).toList()
                        : [],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          DateTimeField(
            onDateSelected: onDateSelected,
            selectedDate: dateSelected,
            mode: DateTimeFieldPickerMode.date,
            decoration: InputDecoration(labelText: context.locals.dateTimeFieldLabel)
                .applyDefaults(Theme.of(context).inputDecorationTheme),
            initialDate: DateTime(2023, 8),
            dateFormat: DateFormat.yMMMMd(),
            use24hFormat: true,
          ),
          const SizedBox(height: 20),
          HWTextFormField(
            controller: contentController,
            labelText: context.locals.dialogHWContent,
            hintText: context.locals.dialogHWContentHint,
            validatorMessage: context.locals.dialogHWContentValidator,
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

class HWTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String?)? onChanged;

  final String? validatorMessage;
  final String labelText;
  final String hintText;
  final String? initValue;
  final int maxLines;

  const HWTextFormField({
    super.key,
    this.maxLines = 1,
    this.controller,
    this.validatorMessage,
    required this.labelText,
    required this.hintText,
    this.initValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) => value!.isEmpty ? validatorMessage : null,
      maxLines: maxLines,
      initialValue: initValue,
      decoration: InputDecoration(labelText: labelText, hintText: hintText),
      onChanged: onChanged,
    );
  }
}
