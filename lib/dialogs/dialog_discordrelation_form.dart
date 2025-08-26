import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/dialogs/dialog_subject_form.dart';
import 'package:hw_manager_flutter/discord_util.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:nyxx/nyxx.dart';

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
  final TextEditingController _webhookUrlController = TextEditingController();
  final TextEditingController _channelNameController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<DiscordRelation> cachedDRs = [];
  final List<GuildChannel> cachedChannels = [];

  GuildChannel? selectedChannel;

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  Future<void> _initStateAsync() async {
    final relations = await DBHelper.retrieveDiscordRelations();
    final channels = (await DiscordHelper().channels)
            ?.where((c) => !relations.map((r) => r.channelID).contains(c.id.value.toString())) ??
        [];
    if (kDebugMode) {
      print("These are the existing channels: $channels");
    }
    cachedDRs.clear();
    cachedChannels.clear();
    setState(() {
      if (widget.dr != null) {
        _webhookUrlController.text = widget.dr!.webhookUrl ?? "";
        final GuildChannel initValue = channels.firstWhere(
          (c) => c.id.value.toString() == widget.dr!.channelID,
          orElse: () => DummyChannel(widget.dr!.channelID, widget.dr!.channelName),
        );
        selectedChannel = initValue;
        if (initValue is DummyChannel) cachedChannels.add(initValue);
      }
      cachedDRs.addAll(relations);
      cachedChannels.addAll(channels);
    });
  }

  Future<void> _saveDiscordRelation(BuildContext context) async {
    final String shortName = _webhookUrlController.text.trim();
    final id = (selectedChannel?.id ?? Snowflake.now()).value.toString();
    final DiscordRelation dr = DiscordRelation(
      channelName: selectedChannel?.name ?? _channelNameController.text,
      channelID: id,
      webhookUrl: shortName,
    );

    if (widget.dr != null) {
      await DBHelper.renameDiscordRelation(
          widget.dr!.channelID, id); // If this is in editing mode, rename dr in database beforehand
    }
    if (selectedChannel?.id == null) discordStatusUpdate("ID: $id");
    await DBHelper.insertDiscordRelation(dr).then((value) => Navigator.pop(context, true));
    SubjectFormDialog.subjectRelationNotifier.notifyListeners();
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
        webhookUrlController: _webhookUrlController,
        cachedDRs: cachedDRs,
        cachedChannels: cachedChannels,
        initValue: () {
          if (widget.dr == null) return null;
          return cachedChannels.firstWhere(
            (c) => c.id.value.toString() == widget.dr!.channelID,
            orElse: () => DummyChannel(widget.dr!.channelID, widget.dr!.channelName),
          );
        }(),
        channelNameController: _channelNameController,
        onChannelSelected: (GuildChannel c) => selectedChannel = c,
      ),
    );
  }
}

class DiscordRelationFormContent extends StatelessWidget {
  const DiscordRelationFormContent({
    super.key,
    required this.formKey,
    required this.onChannelSelected,
    required this.channelNameController,
    required this.webhookUrlController,
    required this.cachedDRs,
    required this.cachedChannels,
    this.initValue,
  });

  final void Function(GuildChannel) onChannelSelected;
  final GuildChannel? initValue;
  final TextEditingController channelNameController;

  final TextEditingController webhookUrlController;
  final GlobalKey<FormState> formKey;
  final Iterable<DiscordRelation> cachedDRs;
  final Iterable<GuildChannel> cachedChannels;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("These are the existing relations: ${cachedDRs.map((e) => e.channelName)}");
    }
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FormField<GuildChannel>(
            initialValue: initValue,
            validator: (value) =>
                value == null || value.name.isEmpty ? context.locals.dialogDiscordRelationChannelNameValidator : null,
            builder: (FormFieldState<GuildChannel> field) {
              channelNameController.addListener(() {
                if (kDebugMode) {
                  print("Modified relation name to: ${channelNameController.text}");
                }
                final DummyChannel channel = DummyChannel.snow(Snowflake.now(), channelNameController.text);
                if (field.hasError || cachedChannels.map((e) => e.id.value).contains(channel.id.value)) return;
                if (field.value != null && field.value!.id.isZero) {
                  // This is the first run
                  return;
                }
                //onChannelSelected(channel);
                // Doesn't matter that this is a dummy channel
              });
              return DropdownMenu<GuildChannel>(
                menuHeight: 250,
                expandedInsets: EdgeInsets.zero,
                errorText: field.hasError ? field.errorText : null,
                requestFocusOnTap: true,
                initialSelection: initValue,
                inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                controller: channelNameController,
                searchCallback: (entries, s) {
                  if (field.value == null || field.value!.id.isZero) {
                    if (kDebugMode) {
                      print("SEARCH != null");
                    }
                    final DummyChannel channel = DummyChannel.snow(Snowflake.now(), channelNameController.text);
                    field.didChange(channel);
                    onChannelSelected(channel);
                  }
                  if (s.isEmpty) return null;

                  final int index = entries.indexWhere((entry) => entry.label.contains(s));

                  return index != -1 ? index : null;
                },
                onSelected: (c) {
                  c ??= DummyChannel.snow(Snowflake.now(), channelNameController.text);
                  field.didChange(c);
                  onChannelSelected(c);
                },
                hintText: context.locals.dialogDiscordRelationChannelNameHint,
                label: Text(context.locals.dialogDiscordRelationChannelName),
                dropdownMenuEntries: DiscordHelper().getCategorizedChannelEntries(cachedChannels.toList()) ?? [],
              );
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: webhookUrlController,
            decoration: InputDecoration(
              labelText: context.locals.dialogDiscordRelationUrl,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.40)),
              hintText: context.locals.dialogDiscordRelationUrlHint,
            ),
          ),
        ],
      ),
    );
  }
}

class DummyChannel implements GuildChannel {
  @override
  String name;
  @override
  Snowflake id;

  DummyChannel(String stringID, this.name) : id = Snowflake.parse(stringID);

  DummyChannel.snow(this.id, this.name);

  @override
  Future<Invite> createInvite(InviteBuilder builder, {String? auditLogReason}) => throw UnimplementedError();

  @override
  String defaultToString() => throw UnimplementedError();

  @override
  Future<void> delete({String? auditLogReason}) => throw UnimplementedError();

  @override
  Future<void> deletePermissionOverwrite(Snowflake id) => throw UnimplementedError();

  @override
  Future<Channel> fetch() => throw UnimplementedError();

  @override
  Future<List<Webhook>> fetchWebhooks() => throw UnimplementedError();

  @override
  Future<void> follow(Snowflake id) => throw UnimplementedError();

  @override
  Future<Channel> get() => throw UnimplementedError();

  @override
  PartialGuild get guild => throw UnimplementedError();

  @override
  Snowflake get guildId => throw UnimplementedError();

  @override
  bool get isNsfw => throw UnimplementedError();

  @override
  Future<List<InviteWithMetadata>> listInvites() => throw UnimplementedError();

  @override
  ChannelManager get manager => throw UnimplementedError();

  @override
  PartialChannel? get parent => throw UnimplementedError();

  @override
  Snowflake? get parentId => null;

  @override
  List<PermissionOverwrite> get permissionOverwrites => throw UnimplementedError();

  @override
  int get position => throw UnimplementedError();

  @override
  ChannelType get type => throw UnimplementedError();

  @override
  Future<Channel> update(UpdateBuilder<Channel> builder) => throw UnimplementedError();

  @override
  Future<void> updatePermissionOverwrite(PermissionOverwriteBuilder builder) => throw UnimplementedError();
}

int? search<T>(List<DropdownMenuEntry<T>> entries, String text) {
  final String searchText = text.toLowerCase();
  if (searchText.isEmpty) {
    return null;
  }
  final int index = entries.indexWhere((DropdownMenuEntry<T> entry) => entry.label.toLowerCase().contains(searchText));

  return index != -1 ? index : null;
}
