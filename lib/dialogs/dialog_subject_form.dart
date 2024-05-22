import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class SubjectFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;
  final Subject? subject;

  static final BasicNotifier subjectRelationNotifier = BasicNotifier();

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
  DiscordRelation? _discordRelation;

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
    _discordRelation = widget.subject!.discordChannel;
  }

  Future<void> _saveSubject(BuildContext context) async {
    final String name = _nameController.text.trim();
    final String shortName = _shortNameController.text.trim();

    final Subject subject = Subject(
      name: name,
      shortName: shortName,
      discordChannel: _discordRelation,
    );

    if (widget.subject != null) {
      DBHelper.deleteSubject(
        widget.subject!.name,
      ); // If this is in editing mode, delete subject beforehand
    }
    await DBHelper.insertSubject(subject).then((value) => Navigator.pop(context, true));
    SubjectFormDialog.subjectRelationNotifier
        .notifyListeners(); // TODO: Implement immediate return value, so we don't have to wait for db
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancel),
        ),
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
        onChannelSelected: (dr) => _discordRelation = dr,
        initChannelSelected: _discordRelation,
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
    required this.onChannelSelected,
    required this.initChannelSelected,
  });

  final TextEditingController nameController;
  final TextEditingController shortNameController;
  final Function(DiscordRelation?) onChannelSelected;
  final DiscordRelation? initChannelSelected;
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
          FutureBuilder(
            future: DBHelper.retrieveDiscordRelations(),
            builder: (context, snapshot) {
              return DropdownMenu<DiscordRelation>(
                menuHeight: 250,
                requestFocusOnTap: true,
                inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                hintText: context.locals.dialogSubjectChannelNameHint,
                label: Text(context.locals.dialogSubjectChannelName),
                expandedInsets: EdgeInsets.zero,
                initialSelection: initChannelSelected != null
                    ? snapshot.data == null
                        ? initChannelSelected
                        : snapshot.data!.firstWhere((element) => element == initChannelSelected)
                    : null,
                onSelected: onChannelSelected,
                searchCallback: (entries, s) {
                  if (entries.where((e) => e.label.contains(s)).isEmpty) {
                    onChannelSelected(null);
                    return null;
                  }

                  final int index = entries.indexWhere((entry) => entry.label.contains(s));

                  return index != -1 ? index : null;
                },
                dropdownMenuEntries: (snapshot.data != null
                        ? snapshot.data!
                        : initChannelSelected != null
                            ? [initChannelSelected!]
                            : <DiscordRelation>[])
                    .map(
                      (s) => DropdownMenuEntry<DiscordRelation>(
                        value: s,
                        label: "${s.channelName} (${s.channelID})",
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
