import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class SubjectFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;
  final Subject? subject;

  const SubjectFormDialog({
    super.key,
    required this.title,
    required this.submit,
    required this.cancel,
    this.subject,
  });

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortNameController = TextEditingController();
  final TextEditingController _dChannelController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  Future<void> _initStateAsync() async {
    if (widget.subject == null) return;
    _nameController.text = widget.subject!.name;
    _shortNameController.text = widget.subject!.shortName ?? "";
    _dChannelController.text = widget.subject!.discordChannel ?? "";
  }

  Future<void> _saveSubject(BuildContext context) async {
    final String name = _nameController.text.trim();
    final String shortName = _shortNameController.text.trim();
    final String dChannel = _dChannelController.text.trim();

    final Subject subject = Subject(name: name, shortName: shortName, discordChannel: dChannel);

    final DBHelper dbHelper = DBHelper();
    if (widget.subject != null) {
      dbHelper.deleteSubject(widget.subject!.name); // If this is in editing mode, delete subject beforehand
    }
    dbHelper.insertSubject(subject).then((value) => Navigator.pop(context, true));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      backgroundColor: Theme.of(context).colorScheme.background,
      actions: [
        ElevatedButton(onPressed: () => Navigator.of(context).pop(false), child: Text(widget.cancel)),
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            _saveSubject(context);
          },
          child: Text(widget.submit),
        ),
      ],
      content: SubjectFormContent(
        formKey: formKey,
        nameController: _nameController,
        shortNameController: _shortNameController,
        dChannelController: _dChannelController,
      ),
    );
  }
}

class SubjectFormContent extends StatelessWidget {
  const SubjectFormContent({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.shortNameController,
    required this.dChannelController,
  });

  final TextEditingController nameController;
  final TextEditingController shortNameController;
  final TextEditingController dChannelController;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: nameController,
            validator: (value) => value!.isEmpty ? context.locals.dialogSubjectFullNameValidator : null,
            decoration: InputDecoration(
              labelText: context.locals.dialogSubjectFullName,
              hintText: context.locals.dialogSubjectFullNameHint,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: shortNameController,
            decoration: InputDecoration(
              labelText: context.locals.dialogSubjectShortName,
              hintText: context.locals.dialogSubjectShortNameHint,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: dChannelController,
            decoration: InputDecoration(
              labelText: context.locals.dialogSubjectChannelName,
              hintText: context.locals.dialogSubjectChannelNameHint,
            ),
          ),
        ],
      ),
    );
  }
}
