import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';

class DiscordRelationFormDialog extends StatefulWidget {
  final String title;
  final String submit;
  final String cancel;
  final DiscordRelation? dr;

  const DiscordRelationFormDialog({
    super.key,
    required this.title,
    required this.submit,
    required this.cancel,
    this.dr,
  });

  @override
  State<DiscordRelationFormDialog> createState() => _DiscordRelationFormDialogState();
}

class _DiscordRelationFormDialogState extends State<DiscordRelationFormDialog> {
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _webhookUrlController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<String> cDRNames = [];

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  Future<void> _initStateAsync() async {
    if (widget.dr == null) return;
    _channelNameController.text = widget.dr!.channelName;
    _webhookUrlController.text = widget.dr!.webhookUrl ?? "";
    final names = (await DBHelper().retrieveDiscordRelations()).map((s) => s.channelName);
    setState(() {
      cDRNames.clear();
      cDRNames.addAll(names);
    });
  }

  Future<void> _saveDiscordRelation(BuildContext context) async {
    final String name = _channelNameController.text.trim();
    final String shortName = _webhookUrlController.text.trim();

    final DiscordRelation dr = DiscordRelation(channelName: name, webhookUrl: shortName);

    final DBHelper dbHelper = DBHelper();
    if (widget.dr != null) {
      dbHelper.deleteDiscordRelation(widget.dr!.channelName); // If this is in editing mode, delete dr beforehand
    }
    dbHelper.insertDiscordRelation(dr).then((value) => Navigator.pop(context, true));
  }

  @override
  Widget build(BuildContext context) {
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
            _saveDiscordRelation(context);
          },
          child: Text(widget.submit),
        ),
      ],
      content: DiscordRelationFormContent(
        formKey: formKey,
        channelNameController: _channelNameController,
        webhookUrlController: _webhookUrlController,
        cachedDRNames: cDRNames,
      ),
    );
  }
}

class DiscordRelationFormContent extends StatelessWidget {
  const DiscordRelationFormContent({
    super.key,
    required this.formKey,
    required this.channelNameController,
    required this.webhookUrlController,
    required this.cachedDRNames,
  });

  final TextEditingController channelNameController;
  final TextEditingController webhookUrlController;
  final GlobalKey<FormState> formKey;
  final Iterable<String> cachedDRNames;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("These are the existing relations: $cachedDRNames");
    }
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: channelNameController,
            validator: (value) => value!.isEmpty || cachedDRNames.contains(value.trim())
                ? context.locals.dialogDiscordRelationChannelNameValidator
                : null,
            decoration: InputDecoration(
              labelText: context.locals.dialogDiscordRelationChannelName,
              labelStyle: TextStyle(color: context.primaryColor),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: MaterialStateOutlineInputBorder.resolveWith((Set<MaterialState> states) {
                final Color color = states.contains(MaterialState.error)
                    ? Color.alphaBlend(context.primaryColor.withAlpha(125), context.inversePrimaryColor)
                    : context.primaryColor;
                return OutlineInputBorder(borderSide: BorderSide(color: color));
              }),
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
              hintText: context.locals.dialogDiscordRelationChannelNameHint,
              errorStyle: TextStyle(color: context.inversePrimaryColor),
              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: context.inversePrimaryColor)),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: webhookUrlController,
            decoration: InputDecoration(
              labelText: context.locals.dialogDiscordRelationUrl,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
              hintText: context.locals.dialogDiscordRelationUrlHint,
            ),
          ),
        ],
      ),
    );
  }
}
