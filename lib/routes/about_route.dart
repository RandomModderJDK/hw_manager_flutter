import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/main.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutRoute extends StatelessWidget {
  const AboutRoute({super.key});

  @override
  Widget build(BuildContext context) {
    //final BasicNotifier discordTokenNotifier = BasicNotifier();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(context.locals.settingsAboutTitle),
          leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            //Name and Logo
            Container(
                padding: const EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Image.asset('assets/foreground-alpha-borderless.png',
                        width: 100, height: 100),
                    const SizedBox(height: 4),
                    Text('HWM - ${HWMApp.of(context).packageVersion}',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                )),

            Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A wonderful homework app, that you can even use collaboratively.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'I really wanted to have a way to store images and tasks with a deadline that works smartly. Therefore there is Untis integration. \n\n'
                      '~ Random',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )),

            Text(
              'Deployment methods:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Native Apps (recommended)'),
              onTap: () => launchUrl(Uri.parse(
                  'https://github.com/RandomModderJDK/hw_manager_flutter/releases/latest')),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Add WebApp to homescreen'),
              onTap: () => launchUrl(Uri.parse(
                  'https://www.macrumors.com/how-to/save-safari-bookmark-web-app-iphone-home-screen/')),
            ),

            ListTile(
              leading:
                  const FaIcon(FontAwesomeIcons.github, color: Colors.white38),
              title: const Text('Source Code'),
              onTap: () => launchUrl(Uri.parse(
                  'https://github.com/RandomModderJDK/hw_manager_flutter')),
            )
          ],
        )));
  }
}
