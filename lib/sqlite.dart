import 'dart:io' as io;

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<bool> initDB() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  final io.Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  // Open the database and store the reference.
  final database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(appDocumentsDir.path, "databases", 'hw_database.db'),
    // When the database is first created, create a table to store homework.
    onCreate: (db, version) {
      return db.execute('CREATE TABLE homeworks('
          'id INTEGER PRIMARY KEY, '
          'subject_short TEXT, '
          'subject TEXT, '
          'overdueDate TEXT, '
          'content TEXT, '
          'finished BOOL'
          ')');
    },
    version: 1,
  );
  return true;
}

class Homework {
  final int id;
  final DateTime overdueDate;
  final Subject subject;
  final String content;
  final bool finished;

  // DateTime needs DateTime.tryParse(isoString);
  const Homework(
      {required this.id,
      required this.subject,
      required this.overdueDate,
      required this.content,
      required this.finished});

  /// Convert a Dog into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_short': subject.shortName,
      'subject': subject.name,
      'overdueDate': overdueDate.toIso8601String(),
      'content': content,
      'finished': finished,
    };
  }

  /// Convert a Homework into a Map.
  Homework fromMap(Map<String, dynamic> map) {
    return Homework(
        id: int.parse(map["id"]),
        subject: map["subject"],
        overdueDate: DateTime.parse(map["overdueDate"]),
        content: map["content"],
        finished: bool.parse(map["finished"]));
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Homework{id: $id, subject: ${subject.name}, content: $content}';
  }
}

class Subject {
  final String name;
  final String shortName;

  const Subject({required this.name, required this.shortName});
}
