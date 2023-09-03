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
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Settings')),
      body: SettingsList(
        sections: [
          // TODO Implement Untis section
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
                title: const Text('OBSOLETE: Persist dialog data'),
                leading: const Icon(Icons.archive_outlined),
                description: const Text(
                    'OBSOLETE: Persist dialog data in-memory to load after closing dialog'),
                onPressed: (context) => Preferences.getDialogPersistence()
                    .then((b) => Preferences.setDialogPersistence(!b)),
              ),
              SettingsTile(
                title: const Text('Subjects overview'),
                leading: const Icon(Icons.subject),
                description:
                    const Text('Delete, insert or edit the suggested subjects'),
                onPressed: (context) => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const SubjectRoute())),
              ),
              SettingsTile(
                title: const Text('Show photo'),
                leading: const Icon(Icons.archive_outlined),
                description: const Text('TEST: Shows photo'),
                onPressed: (context) async => await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                          child: FutureBuilder(
                              future: DBHelper().retrieveHWImagesById(-1),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return ListView.builder(
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, position) {
                                        HWImage img = snapshot.data![position];
                                        return Stack(children: <Widget>[
                                          ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxHeight: 300),
                                              child: Image.memory(img.data,
                                                  fit: BoxFit.contain)),
                                          Align(
                                              alignment: Alignment.topLeft,
                                              child: Text(
                                                img
                                                    .toString()
                                                    .splitMapJoin(", ",
                                                        onMatch: (m) => "\n")
                                                    .split("{")[1],
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ))
                                        ]);
                                      });
                                } else {
                                  print("tes");
                                  return Text("data");
                                }
                              }));
                    }),
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
