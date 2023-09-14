import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class SubjectFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;
  final Subject? subject;

  const SubjectFormDialog({super.key, required this.title, required this.submit, required this.cancel, this.subject});

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortNameController = TextEditingController();

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
    //TODO REIMPLEMENT
    /*bool persisting = await Preferences.getDialogPersistence();
    if (!persisting) {
      setState(() {
        _dateSelected = DateTime.now();
        _userDated = false;
      });
    }*/
  }

  void _saveSubject(BuildContext context) async {
    String name = _nameController.text.trim();
    String shortName = _shortNameController.text.trim();

    Subject subject = Subject(name: name, shortName: shortName);

    DBHelper dbHelper = DBHelper();
    if (widget.subject != null) {
      dbHelper.deleteSubject(name); // If this is in editing mode, delete subject beforehand
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
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
      ),
    );
  }
}

class SubjectFormContent extends StatelessWidget {
  const SubjectFormContent({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.shortNameController,
  }) : super(key: key);

  final TextEditingController nameController;
  final TextEditingController shortNameController;
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
            validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.dialogSubjectFullNameValidator : null,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.dialogSubjectFullName,
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: MaterialStateOutlineInputBorder.resolveWith((Set<MaterialState> states) {
                final Color color = states.contains(MaterialState.error)
                    ? Color.alphaBlend(Theme.of(context).colorScheme.primary.withAlpha(125),
                        Theme.of(context).colorScheme.inversePrimary)
                    : Theme.of(context).colorScheme.primary;
                return OutlineInputBorder(borderSide: BorderSide(color: color));
              }),
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
              hintText: AppLocalizations.of(context)!.dialogSubjectFullNameHint,
              errorStyle: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
              errorBorder:
                  OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.inversePrimary)),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
              controller: shortNameController,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.dialogSubjectShortName,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
                hintText: AppLocalizations.of(context)!.dialogSubjectShortNameHint,
              )),
        ],
      ),
    );
  }
}
