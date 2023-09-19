import 'package:dart_webuntis/untis.dart' as untis;
import 'package:date_field/date_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
              setState(
                () => subjectErrorText =
                    AppLocalizations.of(context)!.dialogHWSubjectValidator,
              );
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
        },
        onSubjectSelected: (s) async {
          if (kDebugMode) {
            print("object: $s");
          }
          if (s == null) return;
          final untis.Subject? subject =
              await UntisHelper().searchSubject(s.name, s.shortName);
          if (kDebugMode) {
            print("object: $subject");
          }
          if (subject == null) return;
          final untis.Period? period =
              await UntisHelper().searchSubjectPeriod(subject);
          if (kDebugMode) {
            print("object: $period");
          }
          if (period == null) return;
          setState(() {
            _dateSelected = period.startTime;
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
    required this.subjectErrorText,
    required this.dateSelected,
    required this.userDated,
    required this.onDateSelected,
    required this.onSubjectSelected,
  });

  final TextEditingController contentController;
  final TextEditingController subjectController;
  final String subjectErrorText;
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: FutureBuilder(
                  future: DBHelper().retrieveSubjects(),
                  builder: (context, snapshot) {
                    final bool isError = subjectErrorText != "";
                    return DropdownMenu<Subject>(
                      expandedInsets: EdgeInsets.zero,
                      controller: subjectController,
                      onSelected: onSubjectSelected,
                      errorText: subjectErrorText,
                      requestFocusOnTap: true,
                      label: Text(
                        AppLocalizations.of(context)!.dialogHWSubject,
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border:
                            MaterialStateOutlineInputBorder.resolveWith((_) {
                          final Color color = isError
                              ? Color.alphaBlend(
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(125),
                                  Theme.of(context).colorScheme.inversePrimary,
                                )
                              : Theme.of(context).colorScheme.primary;
                          return OutlineInputBorder(
                            borderSide: BorderSide(color: color),
                          );
                        }),
                        errorStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isError
                                ? Theme.of(context).colorScheme.inversePrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      dropdownMenuEntries: snapshot.data != null
                          ? snapshot.data!
                              .map(
                                (s) => DropdownMenuEntry(
                                  value: s,
                                  label: s.name,
                                ),
                              )
                              .toList()
                          : [],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          DateTimeField(
            onDateSelected: onDateSelected,
            selectedDate: dateSelected,
            mode: DateTimeFieldPickerMode.date,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.dateTimeFieldLabel,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            initialDate: DateTime(2023, 8),
            dateFormat: DateFormat.yMMMMd(),
            use24hFormat: true,
          ),
          const SizedBox(height: 30),
          HWTextFormField(
            controller: contentController,
            labelText: AppLocalizations.of(context)!.dialogHWContent,
            hintText: AppLocalizations.of(context)!.dialogHWContentHint,
            validatorMessage:
                AppLocalizations.of(context)!.dialogHWContentValidator,
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
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: MaterialStateOutlineInputBorder.resolveWith(
            (Set<MaterialState> states) {
          final Color color = states.contains(MaterialState.error)
              ? Color.alphaBlend(
                  Theme.of(context).colorScheme.primary.withAlpha(125),
                  Theme.of(context).colorScheme.inversePrimary,
                )
              : Theme.of(context).colorScheme.primary;
          return OutlineInputBorder(borderSide: BorderSide(color: color));
        }),
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
        hintText: hintText,
        errorStyle:
            TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
