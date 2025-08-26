import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/l10n/app_localizations.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nyxx/nyxx.dart';

void Function(String text) discordError =
    (String text) => HWMToast(text: text, color: Colors.red, icon: const Icon(Icons.discord_outlined)).show();
void Function(String text) discordConfirmation = (String text) =>
    HWMToast(text: text, color: Colors.green.shade900, icon: const Icon(Icons.discord_outlined)).show();
void Function(String text) discordStatusUpdate = (String text) =>
    HWMToast(text: text, color: Colors.yellow.shade700, icon: const Icon(Icons.discord_outlined)).show();

class DiscordHelper {
  static final DiscordHelper _discordHelper = DiscordHelper._();

  factory DiscordHelper() {
    return _discordHelper;
  }

  DiscordHelper._() {
    loggedInNotifier = BasicNotifier();
  }

  NyxxRest? _client;

  bool get isLoggedIn => _client != null;
  late BasicNotifier loggedInNotifier;

  Future<NyxxRest?> get client async {
    if (_client == null) {
      //&& !await login())
      if (kDebugMode) {
        print("Bot could probably not login to get the client");
      }
    }

    return _client;
  }

  String? _token;

  bool tokenEqualsTo(String? tokenToCheck) => tokenToCheck?.trim() == _token?.trim();

  Future<bool> login(String token) async {
    _token = token;
    if (_token == null || _token!.isEmpty) {
      _client = null;
      loggedInNotifier.notifyListeners();
      return false;
    }
    try {
      _client = await Nyxx.connectRest(
        token,
        options: clientOptions(),
      );
      loggedInNotifier.notifyListeners();
    } on HttpResponseError {
      _client = null;
      loggedInNotifier.notifyListeners();
      return false;
    }
    if (_client == null) {
      loggedInNotifier.notifyListeners();
      return false;
    }
    if (kDebugMode) {
      final botUser = await _client!.users.fetchCurrentUser();
      print(botUser.username);
    }
    return true;
  }

  UserGuild? _guild;

  Future<UserGuild?> get guild async {
    if (await client == null) return null;
    if (_guild == null && !await refreshGuildCache()) {
      if (kDebugMode) print("Bot couldn't fetch guild");
    }
    return _guild;
  }

  Future<bool> refreshGuildCache() async {
    _guild = null;
    if (await client == null) return false;

    _guild = (await _client!.listGuilds(limit: 1)).firstOrNull;
    return _guild != null;
  }

  List<GuildChannel>? _channels;

  Future<List<GuildChannel>?> get channels async {
    if (_channels == null && !await refreshChannelCache()) {
      if (kDebugMode) print("Bot couldn't fetch channels");
    }
    return _channels;
  }

  List<DropdownMenuEntry<GuildChannel>>? getCategorizedChannelEntries(
    List<GuildChannel>? channels, {
    bool showId = true,
  }) {
    if (channels == null) return null;
    return channels.where((c) => c is! GuildCategory && c is! ThreadsOnlyChannel).map((c) {
      Widget? labelWidget;
      if (c.parentId != null) {
        // This channel is in a category
        final GuildChannel category = channels.firstWhere((cat) => cat.id.value == c.parentId!.value);
        final List<GuildChannel> channelsInCategory = channels.where((c1) => c1.parentId == c.parentId).toList();
        //print("${category.position} ${c.position}");
        //print("${category.name} ${c.name}");
        if (channelsInCategory.indexOf(c) == 0) {
          labelWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(style: const TextStyle(fontWeight: FontWeight.bold), "${category.name}:"),
              Row(
                children: [const Text(style: TextStyle(fontWeight: FontWeight.bold), " ╚ "), Text(c.name)],
              ),
            ],
          );
        } else {
          labelWidget = Row(
            children: [const Text(style: TextStyle(fontWeight: FontWeight.bold), " ╚ "), Text(c.name)],
          );
        }
      }
      return DropdownMenuEntry(
        value: c,
        labelWidget: labelWidget,
        label: c.name,
        trailingIcon: showId ? Text("(${c.id})") : null,
      );
    }).toList();
  }

  static final channelTypeGroups = () {
    final channelTypeGroups = [
      [ChannelType.guildAnnouncement, ChannelType.guildText],
    ];
    channelTypeGroups.addAll(
      ChannelType.values.where((t) => !channelTypeGroups.expand((l) => l).contains(t)).map((t) => [t]).toList(),
    );
    /*
    List<ChannelType> getTypeGroup(ChannelType type) => channelTypeGroups.firstWhere((g) => g.contains(type));

    assert(getTypeGroup(ChannelType.guildText).contains(ChannelType.guildAnnouncement));
    assert(!getTypeGroup(ChannelType.guildVoice).contains(ChannelType.guildText));*/
    return channelTypeGroups;
  }();

  int sortForChannels(GuildChannel a, GuildChannel b) {
    final bool sameCategory = channelTypeGroups.firstWhere((g) => g.contains(a.type)).contains(b.type);
    return sameCategory
        ? a.position - b.position
        : channelTypeGroups.indexWhere((t) => t.contains(a.type)) -
            channelTypeGroups.indexWhere((t) => t.contains(b.type));
  }

  Future<bool> refreshChannelCache() async {
    _channels = null;
    if (await client == null) return false;
    final List<GuildChannel>? c = await (await guild)?.fetchChannels();
    _channels = c?.toList();
    if (_channels?.where((c) => c.parentId != null).firstOrNull != null) {
      // Sort by categories->types->position
      final List<MapEntry<GuildChannel, List<GuildChannel>>> groupedIntoCategories =
          _channels!.where((c) => c.parentId == null).map((c) => MapEntry(c, <GuildChannel>[])).toList();
      groupedIntoCategories.sort((a, b) => sortForChannels(a.key, b.key));
      for (final category in groupedIntoCategories) {
        category.value.addAll(_channels!.where((c) => c.parentId == category.key.id));
        category.value.sort(sortForChannels);
      }
      _channels =
          groupedIntoCategories.map((ent) => ent.value..insert(0, ent.key)).expand((entries) => entries).toList();
      assert(c!.sublist(0).where((element) => !_channels!.contains(element)).isEmpty);
    }
    return _channels != null;
  }

  /// Deletes message of webhook
  ///
  /// Returns true, when homework doesn't have message id
  Future<bool> deleteWebhookMessage(String url, Homework homework) async {
    try {
      final BasicWebhook wh = BasicWebhook.fromUrlString(url);
      if (homework.messageID == null || homework.messageID!.isEmpty) return true;
      try {
        await wh.delete(Snowflake.parse(homework.messageID!));
      } catch (error) {
        rethrow;
      }

      homework.messageID = null;
      DBHelper.insertHomework(homework);
    } catch (s) {
      if (kDebugMode) {
        print(s);
      }
      discordError(locals.discordNetworkError(s.toString()));
      return false;
    }
    return true;
  }

  // TODO: Send a color which is stored in the hw's subject
  Future<bool> sendWebhook(String url, Homework homework) async {
    var pages = await DBHelper.retrieveHWPages(homework);
    if (pages.length > 10) {
      discordStatusUpdate(locals.discordWebhookTooManyPagesError);
      pages = pages.where((p) => p.order < 10).toList();
    }
    try {
      final BasicWebhook wh = BasicWebhook.fromUrlString(url);
      Snowflake msgID;
      if (homework.messageID == null || homework.messageID!.isEmpty) {
        msgID = await wh.execute(toBuiltMessage(homework, pages) as MessageBuilder);
      } else {
        try {
          msgID = await wh.edit(
            Snowflake.parse(homework.messageID!),
            toBuiltMessage(homework, pages, update: true) as MessageUpdateBuilder,
          );
        } catch (error) {
          if (error is ArgumentError && (error.message as String).contains("{message: Unknown Message, code: 10008}")) {
            // This needs to check whether the message exists or if it was removed or smth.
            discordStatusUpdate(locals.discordWebhookMessageEditNotPossible);
            msgID = await wh.execute(toBuiltMessage(homework, pages) as MessageBuilder);
          } else if (error is ArgumentError &&
              (error.message as String).contains("{message: Unknown Webhook, code: 10015}")) {
            discordError(locals.discordWebhookURLInvalid);
            return false;
          } else {
            rethrow;
          }
        }
      }
      homework.messageID = msgID.toString();
      DBHelper.insertHomework(homework);
      //if (msgID == null) return false;
    } catch (s) {
      if (kDebugMode) {
        print(s);
      }
      discordError(locals.discordNetworkError(s.toString()));
      return false;
    }
    return true;
  }

  RestClientOptions Function() clientOptions = () => RestClientOptions(
        plugins: [
          Logging(stdout: kIsWeb ? FallbackStringSink() : null, stderr: kIsWeb ? FallbackStringSink("[ERR] ") : null),
          if (!kIsWeb) cliIntegration,
        ],
      );

  Future<TextChannel?> getTextChannel(String channelID) async {
    final channels = await this.channels;
    if (channels == null) return null;
    final allChannel = channels.where((c) => c.id.value.toString() == channelID);
    if (allChannel.isEmpty || allChannel.firstOrNull is! TextChannel) {
      if (kDebugMode) print("Channel $channelID cant be accessed with discord bot");
      return null;
    }
    return allChannel.first as TextChannel;
  }

// The format of a Message is:
  /* {
  "username":"Homework","content":"",
  "avatar_url":"https://productimages.artboxone.com/929001056-PO-big.jpg",
  "embeds":[{"title":"Englisch","description":"Aufgabe","author":{"icon_url":"","name":"Bis zum 02."}}]
  }*/
  Future<Map<Homework, List<Uint8List>>> fetchHomework() async {
    final Map<Homework, List<Uint8List>> list = {};
    int successesResolving = 0;
    int channelsChecked = 0;
    for (final DiscordRelation dr in await DBHelper.retrieveDiscordRelations()) {
      final List<Subject> subj = await DBHelper.retrieveSubjectsIn(dr.channelID);
      // TODO: Ask if it only should check for subjects which are from a particular channel or all existing ones
      if (subj.isEmpty) continue;
      channelsChecked += 1;
      final c = await getTextChannel(dr.channelID);
      if (c == null) {
        if (kDebugMode) print("${dr.channelID}is not a channel");
        continue;
      }
      final messages = await c.messages.fetchMany(limit: 15);
      successesResolving += 1;
      for (final Message msg in messages) {
        try {
          final Embed embed = msg.embeds.first;
          if (embed.author == null) continue;
          if (embed.title == null) continue;
          final String dateTimeS = embed.author!.name;
          DateTime dateTime;
          try {
            dateTime = DateFormat.yMd().parse(dateTimeS.split(" ")[1]);
          } on FormatException {
            try {
              final String lastLocale = AppLocalizations.supportedLocales.map((e) => e.languageCode).last;
              final String firstLocale = AppLocalizations.supportedLocales.map((e) => e.languageCode).first;
              if (lastLocale == locals.localeName) {
                await initializeDateFormatting(firstLocale);
                dateTime = DateFormat.yMd(firstLocale).parse(dateTimeS.split(" ")[1]);
              } else {
                await initializeDateFormatting(lastLocale);
                dateTime = DateFormat.yMd(lastLocale).parse(dateTimeS.split(" ")[1]);
                if (kDebugMode) {
                  print(
                    "Trying last supported locale ${AppLocalizations.supportedLocales.map((e) => e.languageCode).last}",
                  );
                }
              }
            } catch (e) {
              throw StateError(
                "${locals.localeName} There is no matching locale for the given date ${dateTimeS.split(" ")[1]} ($dateTimeS)",
              );
            }
          }
          try {
            final DateTime time = DateFormat.Hm().parse(dateTimeS.split(" ")[3]);
            dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute);
          } catch (e) {
            if (kDebugMode) {
              print("Time fetching failed with msg: $dateTimeS");
            }
          }
          if (embed.title == null || embed.title == "") throw StateError("There is no title/subject in this message");
          // TODO: Be careful about subjects' longName being with parenthesis
          bool isExactMatch(Subject s, Embed embed) => embed.title == "${s.name} (${s.shortName})";
          bool equalsIgnoreShortName(Subject s, Embed embed) =>
              s.name == embed.title!.substring(0, embed.title!.length - (embed.title!.split(" (").last.length + 2));

          final Subject? matchingSubj;
          final Subject? exactMatch = subj.where((s) => isExactMatch(s, embed)).firstOrNull;
          if (exactMatch != null) {
            matchingSubj = exactMatch;
          } else if (embed.title!.split(" (").length == 1) {
            // If there is no shortName in the message
            // TODO: Add option to be really exact about the names, to not include things with just a matching longName
            //       When enabled should this be still null
            matchingSubj = subj.where((s) => s.name == embed.title!).firstOrNull;
          } else {
            matchingSubj = subj.where((s) => equalsIgnoreShortName(s, embed)).firstOrNull;
          }
          if (matchingSubj == null) {
            // TODO: Implement ask for creating subject, if this subj doesn't exist in local subjects
            if (kDebugMode) {
              // Test equalsIgnoreShortName
              const Subject testS = Subject(name: "test");
              final Embed testEmbed = Embed(
                  title: "test (hehea)",
                  description: "description",
                  url: null,
                  timestamp: null,
                  color: null,
                  footer: null,
                  image: null,
                  thumbnail: null,
                  video: null,
                  provider: null,
                  author: null,
                  fields: null);
              assert(equalsIgnoreShortName(testS, testEmbed));

              print("Does not have a matching local subject");
              print(
                "Local subjects don't contain ${embed.title!.substring(0, embed.title!.length - (embed.title!.split(" (").last.length + 2))} which has the discord channel specified",
              );
            }
            continue;
          }
          final Homework hw = Homework(
            subject: matchingSubj,
            overdueTimestamp: dateTime,
            // TODO: Save this in the message? SO its the actual creation date
            creationTimestamp: msg.timestamp,
            content: embed.description!,
            finished: false,
            messageID: msg.id.toString(),
          );
          final List<Uint8List?> pages = List.filled(msg.attachments.length, null);
          if (msg.attachments.isNotEmpty) {
            for (final Attachment att in msg.attachments) {
              // We just assume it is an image TODO: Verify that this is an image
              final Uint8List imageBytes = await att.fetch();
              final String order = att.fileName.split("-").last.split(".")[0];
              pages[int.parse(order)] = imageBytes;
            }
          }
          list.putIfAbsent(hw, () => pages.where((element) => element != null).map((e) => e!).toList());
        } on StateError catch (e) {
          // TODO: Use a better way than to catch an error
          if (kDebugMode) print("Couldn't fetch a msg: ${e.message}");
        }
      }
    }
    if (channelsChecked != successesResolving) {
      discordStatusUpdate(locals.discordOnlyCertainChannelsChecked(successesResolving, channelsChecked));
    }
    return list;
  }

  // The format of a Message is:
  /* {
  "username":"Homework","content":"",
  "avatar_url":"https://productimages.artboxone.com/929001056-PO-big.jpg",
  "embeds":[{"title":"Englisch","description":"Aufgabe","author":{"icon_url":"","name":"Bis zum 02."}}]
  }*/
  dynamic toBuiltMessage(Homework hw, List<HWPage> pages, {bool update = false}) {
    final String task = hw.content;
    final String subject = hw.subject.name +
        (hw.subject.shortName == null || hw.subject.shortName == "" ? "" : " (${hw.subject.shortName})");
    final DateTime date = hw.overdueTimestamp.toLocal();
    final String tillDate = locals.dateAnywhereElse(date, date, date, date.hour);
    final List<AttachmentBuilder> att = pages
        .where((p) => p.order < 9) // Discord doesn't support more than 10 messages
        .map((p) => AttachmentBuilder(data: p.data, fileName: "$subject-${date.toIso8601String()}-${p.order}.png"))
        .toList();
    /*List<EmbedBuilder> attEmbeds = att
        .map(
          (att) => EmbedBuilder(
            image: EZEmbedImageBuilder("attachment://${att.fileName.replaceAll(":", "")}"),
          ),
        )
        .toList();*/
    // TODO: add this message to preferences
    const String generalMessage = "Eine neue Hausaufgabe:";
    if (update) {
      return MessageUpdateBuilder(
        content: generalMessage,
        embeds: [
          EmbedBuilder(title: subject, description: task, author: EmbedAuthorBuilder(name: tillDate)),
          // ...attEmbeds,
        ],
        attachments: att,
      );
    }
    return MessageBuilder(
      content: generalMessage,
      embeds: [
        EmbedBuilder(title: subject, description: task, author: EmbedAuthorBuilder(name: tillDate)),
        //...attEmbeds,
      ],
      attachments: att,
    );
  }
}

class EZEmbedImageBuilder extends EmbedImageBuilder {
  String urlS;

  EZEmbedImageBuilder(this.urlS) : super(url: Uri());

  @override
  Map<String, Object?> build() => {
        'url': urlS,
      };
}

class BasicWebhook {
  /// The id of this entity.
  final Snowflake id;

  /// The type of this webhook.
  final WebhookType type;

  /// The ID of the guild this webhook is for, if any.
  final Snowflake? guildId;

  /// The ID of the channel this webhook is for, if any.
  final Snowflake? channelId;

  /// The user this webhook was created by.
  final User? user;

  /// The default name of this webhook.
  final String? name;

  /// The hash of this webhook's default avatar image.
  final String? avatarHash;

  /// If this is a [WebhookType.incoming] webhook, this webhook's token.
  final String? token;

  /// The ID of the application that created this webhook.
  final Snowflake? applicationId;

  final PartialGuild? sourceGuild;

  /// If this is a [WebhookType.channelFollower], this webhook's source channel.
  final PartialChannel? sourceChannel;

  /// The URL to use to execute the webhook.
  final Uri? url;

  /// {@macro webhook}
  /// @nodoc
  BasicWebhook({
    required this.id,
    required this.type,
    required this.guildId,
    required this.channelId,
    required this.user,
    required this.name,
    required this.avatarHash,
    required this.token,
    required this.applicationId,
    required this.sourceGuild,
    required this.sourceChannel,
    required this.url,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || (other is BasicWebhook && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BasicWebhook($id)';

  factory BasicWebhook.fromUrlString(String url) {
    final List<String> splitUrl = url.split("/");
    if (splitUrl.length < 7) throw const FormatException("This is not a valid webhook url, length below 7");

    final BigInt? id = BigInt.tryParse(splitUrl[5]);
    if (id == null) throw const FormatException("This is not a valid webhook url, no id");
    final String token = splitUrl[6];
    return BasicWebhook(
      id: Snowflake.fromBigInt(id),
      type: WebhookType.incoming,
      guildId: null,
      channelId: null,
      user: null,
      name: null,
      avatarHash: null,
      token: token,
      applicationId: null,
      sourceGuild: null,
      sourceChannel: null,
      url: null,
    );
  }

  final httpClient = http.Client();

  Future<Snowflake> execute(
    MessageBuilder builder, {
    bool? wait = true,
    Snowflake? threadId,
    String? threadName,
    List<Snowflake>? appliedTags,
    String? username = "Hausaufgaben", // TODO: at these options to preferences
    String? avatarUrl = "https://productimages.artboxone.com/929001056-PO-big.jpg",
  }) async =>
      (await _execute(
        id,
        builder,
        token: token!,
        wait: wait,
        threadId: threadId,
        threadName: threadName,
        appliedTags: appliedTags,
        username: username,
        avatarUrl: avatarUrl,
      ))!;

  /// Execute a webhook.
  Future<Snowflake?> _execute(
    Snowflake id,
    MessageBuilder builder, {
    required String token,
    bool? wait = true,
    Snowflake? threadId,
    String? threadName,
    List<Snowflake>? appliedTags,
    String? username,
    String? avatarUrl,
  }) async {
    final apiOptions = RestApiOptions(token: "");

    final queryParameters = {
      if (wait != null) 'wait': wait.toString(),
      if (threadId != null) 'thread_id': threadId.toString(),
    };
    final route = Uri.https(apiOptions.host, "${apiOptions.baseUri}/webhooks/$id/$token", queryParameters);
    final BaseRequest request;
    if (builder.attachments != null && builder.attachments!.isNotEmpty) {
      final attachments = builder.attachments!;
      final payload = {
        ...builder.build(),
        if (threadName != null) 'thread_name': threadName,
        if (appliedTags != null) 'applied_tags': appliedTags.map((e) => e.toString()),
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
      final files = <MultipartFile>[];
      for (int i = 0; i < attachments.length; i++) {
        files.add(
          MultipartFile.fromBytes(
            'files[$i]',
            attachments[i].data,
            filename: attachments[i].fileName,
          ),
        );

        ((payload['attachments']! as List)[i] as Map)['id'] = i.toString();
      }

      final multiReq = http.MultipartRequest('POST', route);
      if (!kIsWeb) multiReq.headers.addAll({"User-Agent": apiOptions.userAgent});
      multiReq
        ..fields.addAll({'payload_json': jsonEncode(payload)})
        ..files.addAll(files);
      request = multiReq;
    } else {
      final http.Request req = http.Request('POST', route);
      if (!kIsWeb) req.headers.addAll({"User-Agent": apiOptions.userAgent});
      req.headers.addAll({'Content-Type': 'application/json'});
      req.body = jsonEncode({
        ...builder.build(),
        if (threadName != null) 'thread_name': threadName,
        if (appliedTags != null) 'applied_tags': appliedTags.map((e) => e.toString()),
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      request = req;
    }
    final http.StreamedResponse response = await httpClient.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) throw "Rate Limited";
      try {
        final jsonBody = jsonDecode(utf8.decode(await response.stream.toBytes()));
        throw "Error json: $jsonBody";
      } on FormatException {
        throw "Error whilst parsing JSON";
      }
    }

    if (wait != true) {
      return null;
    }
    final Map<String, Object?> jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(await response.stream.toBytes())) as Map<String, Object?>;
    } on FormatException {
      throw "Error whilst parsing JSON";
    }

    final channelId = Snowflake.parse(jsonBody['id']!);
    /*final messageManager = ((await client)!.channels[channelId] as PartialTextChannel).messages;
    final message = messageManager.parse(jsonBody as Map<String, Object?>);*/

    return channelId;
  }

  Future<Snowflake> edit(Snowflake messageID, MessageUpdateBuilder builder, {Snowflake? threadId}) async =>
      (await _edit(id, messageID, builder, token: token!, threadId: threadId))!;

  /// Edit a webhook messagge.
  Future<Snowflake?> _edit(
    Snowflake webhookId,
    Snowflake messageId,
    MessageUpdateBuilder builder, {
    required String token,
    Snowflake? threadId,
  }) async {
    final apiOptions = RestApiOptions(token: "");

    final queryParameters = {if (threadId != null) 'thread_id': threadId.toString()};
    final route =
        Uri.https(apiOptions.host, "${apiOptions.baseUri}/webhooks/$id/$token/messages/$messageId", queryParameters);
    final BaseRequest request;
    if (builder.attachments != null && builder.attachments! is! List<Never> && builder.attachments!.isNotEmpty) {
      final attachments = builder.attachments!; // Discord doesn't allow more than 10 attachments, maybe put check here
      final payload = builder.build();

      final files = <MultipartFile>[];
      for (int i = 0; i < attachments.length; i++) {
        files.add(
          MultipartFile.fromBytes(
            'files[$i]',
            attachments[i].data,
            filename: attachments[i].fileName,
          ),
        );

        ((payload['attachments']! as List)[i] as Map)['id'] = i.toString();
      }

      final multiReq = http.MultipartRequest('PATCH', route);
      if (!kIsWeb) multiReq.headers.addAll({"User-Agent": apiOptions.userAgent});

      multiReq
        ..fields.addAll({'payload_json': jsonEncode(payload)})
        ..files.addAll(files);
      request = multiReq;
    } else {
      final http.Request req = http.Request('PATCH', route);
      if (!kIsWeb) req.headers.addAll({"User-Agent": apiOptions.userAgent});
      req.headers.addAll({'Content-Type': 'application/json'});
      req.body = jsonEncode(builder.build());
      request = req;
    }
    final http.StreamedResponse response = await httpClient.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) throw "Rate Limited";
      try {
        final jsonBody = jsonDecode(utf8.decode(await response.stream.toBytes()));
        throw ArgumentError("${response.statusCode}: $jsonBody");
      } on FormatException {
        throw const FormatException("Error whilst parsing JSON");
      }
    }

    final Map<String, Object?> jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(await response.stream.toBytes())) as Map<String, Object?>;
    } on FormatException {
      throw const FormatException("Error whilst parsing JSON, but an OK response");
    }

    final channelId = Snowflake.parse(jsonBody['id']!);
    /*final messageManager = ((await client)!.channels[channelId] as PartialTextChannel).messages;
    final message = messageManager.parse(jsonBody as Map<String, Object?>);*/

    return channelId;
  }

  Future<void> delete(Snowflake messageID, {Snowflake? threadId}) async =>
      await _delete(id, messageID, token: token!, threadId: threadId);

  Future<void> _delete(Snowflake webhookId, Snowflake messageId, {required String token, Snowflake? threadId}) async {
    final apiOptions = RestApiOptions(token: "");

    final queryParameters = {if (threadId != null) 'thread_id': threadId.toString()};
    final route = Uri.https(
        apiOptions.host, "${apiOptions.baseUri}/webhooks/$webhookId/$token/messages/$messageId", queryParameters);
    final http.Request req = http.Request('DELETE', route);
    if (!kIsWeb) req.headers.addAll({"User-Agent": apiOptions.userAgent});
    req.headers.addAll({'Content-Type': 'application/json'});
    //req.body = jsonEncode(builder.build());
    final http.StreamedResponse response = await httpClient.send(req);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 204) return;
      if (response.statusCode == 429) throw "Rate Limited";
    }
  }
}

class FallbackStringSink implements StringSink {
  final String prefix;

  FallbackStringSink([this.prefix = ""]);

  @override
  void write(Object? object) {
    if (kDebugMode) {
      print(prefix + object.toString());
    }
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = ""]) {
    if (kDebugMode) {
      print(prefix + object.toString());
    }
  }
}
