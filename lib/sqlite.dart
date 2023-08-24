import 'dart:io' as io;

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// TODO Add search function/do not return the whole list of homeworks
class DBHelper {
  static final DBHelper _dbHelper = DBHelper._();

  DBHelper._();

  late Database db;

  factory DBHelper() {
    return _dbHelper;
  }

  Future<bool> initDB() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Avoid errors caused by flutter upgrade.
    // Importing 'package:flutter/widgets.dart' is required.
    WidgetsFlutterBinding.ensureInitialized();
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    // Open the database and store the reference.
    db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(appDocumentsDir.path, "databases", 'hw_database.db'),
      // When the database is first created, create a table to store homework.
      onCreate: (db, version) {
        return db.execute('CREATE TABLE homeworks('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'subject_short TEXT NOT NULL, '
            'subject TEXT NOT NULL, '
            'overdueDate TEXT NOT NULL, '
            'content TEXT NOT NULL, '
            'finished BOOL NOT NULL'
            ')');
      },
      version: 1,
    );
    return true;
  }

// Define a function that inserts and replaces Homework into the database
  /// Inserts or updates homework supplied into database
  Future<int> insertHomework(Homework hw) async {
    return await db.insert(
      'homeworks',
      hw.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Homework>> retrieveHomeworks() async {
    final List<Map<String, Object?>> queryResult =
        await db.query('homeworks', orderBy: "overdueDate");
    return queryResult.map((e) => Homework.fromMap(e)).toList();
  }

  // Deletes homework from database. If homework does not have id, nothing will be deleted
  Future<void> deleteHomework(Homework hw) async {
    return await deleteHomeworkById(hw.id ?? -1);
  }

  Future<void> deleteHomeworkById(int id) async {
    await db.delete(
      'homeworks',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

class Homework {
  final int? id;
  final DateTime overdueDate;
  final DateTime creationDate;
  final Subject subject;
  final String content;
  final bool finished;

  // DateTime needs DateTime.tryParse(isoString);
  const Homework(
      {this.id,
      required this.subject,
      required this.overdueDate,
      required this.creationDate,
      required this.content,
      required this.finished});

  /// Convert a Homework into a Map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subject_short': subject.shortName,
      'subject': subject.name,
      'overdueDate': overdueDate.toIso8601String(),
      'creationDate': creationDate.toIso8601String(),
      'content': content,
      'finished': finished,
    };
  }

  /// Convert a Homework into a Map.
  static Homework fromMap(Map<String, dynamic> map) {
    return Homework(
        id: int.parse(map["id"]),
        subject: map["subject"],
        overdueDate: DateTime.parse(map["overdueDate"]),
        creationDate: DateTime.parse(map["overdueDate"]),
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
