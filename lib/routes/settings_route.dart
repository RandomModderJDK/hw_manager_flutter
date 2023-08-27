import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../main.dart';
import '../shared_preferences.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('General'),
            tiles: [
              SettingsTile(
                title: const Text('Dark Mode'),
                leading: const Icon(Icons.dark_mode_outlined),
                description:
                    const Text('Change between dark, light, automatic mode'),
                onPressed: (context) {
                  Preferences.nextThemeMode()
                      .then((mode) => HWMApp.of(context).changeTheme(mode));
                },
              ),
              SettingsTile(
                title: const Text('Persist dialog data'),
                leading: const Icon(Icons.archive_outlined),
                description: const Text(
                    'Persist dialog data in-memory to load after closing dialog'),
                onPressed: (context) => Preferences.getDialogPersistence()
                    .then((b) => Preferences.setDialogPersistence(!b)),
              )
            ],
          ), /*
          SettingsSection(
            title: const Text('Replications'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.settings),
                title: const Text('Android Settings Screen'),
                onPressed: (context) {},
              ),
            ],
          ),*/
        ],
      ),
    );
  }
}
