import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<bool> initDB() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  // Open the database and store the reference.
  final database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'doggie_database.db'),
    // When the database is first created, create a table to store dogs.
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      );
    },
// Set the version. This executes the onCreate function and provides a
// path to perform database upgrades and downgrades.
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

  const Homework(
      {required this.id,
      required this.subject,
      required this.overdueDate,
      required this.content,
      required this.finished});

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_short': subject.shortName,
      'subject': subject.name,
      'overdueDate': overdueDate,
      'content': content,
      'finished': finished,
    };
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
