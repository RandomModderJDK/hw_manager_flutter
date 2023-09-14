import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/routes/subject_route.dart';
import 'package:hw_manager_flutter/sqlite.dart';
import 'package:settings_ui/settings_ui.dart';

import '../main.dart';
import '../shared_preferences.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: const Text('Settings')),
      body: SettingsList(
        sections: [
          // TODO Implement Untis section
          SettingsSection(
            title: const Text('General'),
            tiles: [
              SettingsTile(
                title: const Text('Dark Mode'),
                leading: const Icon(Icons.dark_mode_outlined),
                description: const Text('Change between dark, light, automatic mode'),
                onPressed: (context) {
                  Preferences.nextThemeMode().then((mode) => HWMApp.of(context).changeTheme(mode));
                },
              ),
              SettingsTile(
                title: const Text('Subjects overview'),
                leading: const Icon(Icons.subject),
                description: const Text('Delete, insert or edit the suggested subjects'),
                onPressed: (context) =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SubjectRoute())),
              ),
              SettingsTile(
                title: const Text('Untis Login'),
                leading: const Icon(Icons.login_outlined),
                description: const Text('Login with your Untis school account'),
                onPressed: (context) =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SubjectRoute())),
              ),
              SettingsTile(
                title: const Text('Delete all fotos'),
                leading: const Icon(Icons.delete),
                description: const Text('Delete all the photos'),
                onPressed: (context) => DBHelper().deleteAllHWPages(),
              ),
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
