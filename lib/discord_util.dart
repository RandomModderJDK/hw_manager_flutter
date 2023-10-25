import 'package:flutter/foundation.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:nyxx/nyxx.dart';

class DiscordHelper {
  static final DiscordHelper _discordHelper = DiscordHelper._();

  factory DiscordHelper() {
    return _discordHelper;
  }

  DiscordHelper._();

  NyxxGateway? client;

  Future<bool> login() async {
    try {
      client = await Nyxx.connectGateway(
        await Preferences.getDiscordToken(),
        GatewayIntents.allUnprivileged | GatewayIntents.guildMessages,
        options: GatewayClientOptions(plugins: [logging, cliIntegration]),
      );
    } on HttpResponseError {
      return false;
    }
    if (client == null) return false;
    final botUser = await client!.users.fetchCurrentUser();
    if (kDebugMode) {
      print(botUser.username);
    }
    return true;
  }

  Future<bool> sendWebhook(String url, Homework homework) async {
    if (client == null) if (!await login()) return false;
    try {
      final Webhook wh = BasicWebhook.fromUrlString(url, client!);
      final Message? msg = await wh.executeAuth(MessageBuilder(content: homework.content));
      if (msg == null) return false;
    } on HttpResponseError {
      return false;
    }
    return true;
  }
}

extension BasicWebhook on Webhook {
  Future<Message?> executeAuth(
    MessageBuilder builder, {
    Snowflake? threadId,
  }) async {
    if (token == null) return null;
    return execute(builder, token: token!, wait: true);
  }

  static Webhook fromUrlString(String url, NyxxRest client) {
    final List<String> splitUrl = url.split("/");
    if (splitUrl.length < 7) throw const FormatException("This is not a valid webhook url");

    final int? id = int.tryParse(splitUrl[5]);
    if (id == null) throw const FormatException("This is not a valid webhook url");
    final String token = splitUrl[6];

    return Webhook(
      id: Snowflake(id),
      manager: client.webhooks,
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
}
