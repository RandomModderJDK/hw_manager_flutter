import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// TODO Add search function/do not return the whole list of homeworks
class DBHelper {
  static final DBHelper _dbHelper = DBHelper._();

  DBHelper._();

  late Database db;
  late Database subDb;

  factory DBHelper() {
    return _dbHelper;
  }

  Future<bool> initDBs() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Avoid errors caused by flutter upgrade.
    // Importing 'package:flutter/widgets.dart' is required.
    WidgetsFlutterBinding.ensureInitialized();
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    if (kDebugMode) {
      print(
          "Saving/open database to/on ${join(appDocumentsDir.path, "databases", 'hw_database.db')}");
    }
    // Open the database and store the reference.
    db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(appDocumentsDir.path, "databases", 'hw_database.db'),
      // When the database is first created, create a table to store homework.
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE subjects('
            'name TEXT PRIMARY KEY, '
            'shortName TEXT '
            ')');
        return db.execute('CREATE TABLE homeworks('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'subject_short TEXT, '
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

  /// Inserts or updates homework supplied into database
  Future<int> insertSubject(Subject subject) async {
    return await db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subject>> retrieveSubjects() async {
    final List<Map<String, Object?>> queryResult = await db.query('subjects');
    return queryResult.map((e) => Subject.fromMap(e)).toList();
  }

  Future<void> deleteSubject(String name) async {
    await db.delete(
      'subjects',
      where: "name = ?",
      whereArgs: [name],
    );
  }

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
  final DateTime overdueTimestamp;
  final DateTime creationTimestamp;
  final Subject subject;
  final String content;
  final bool finished;

  // DateTime needs DateTime.tryParse(isoString);
  const Homework(
      {this.id,
      required this.subject,
      required this.overdueTimestamp,
      required this.creationTimestamp,
      required this.content,
      required this.finished});

  /// Convert a Homework into a Map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subject_short': subject.shortName,
      'subject': subject.name,
      'overdueDate': overdueTimestamp.toIso8601String(),
      'creationDate': creationTimestamp.toIso8601String(),
      'content': content,
      'finished': finished,
    };
  }

  /// Convert a Homework into a Map.
  static Homework fromMap(Map<String, dynamic> map) {
    return Homework(
        id: int.parse(map["id"]),
        subject: Subject(name: map["subject"], shortName: map["subject_short"]),
        overdueTimestamp: DateTime.parse(map["overdueDate"]),
        creationTimestamp: DateTime.parse(map["overdueDate"]),
        content: map["content"],
        finished: bool.parse(map["finished"]));
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Homework{id: $id, subject: ${subject.name}, overdue at: ${overdueTimestamp.toIso8601String()} content: $content}';
  }
}

class Subject {
  final String name;
  final String? shortName;

  const Subject({required this.name, this.shortName});

  /// Convert a Subject into a Map.
  Map<String, Object?> toMap() {
    return {
      'name': name,
      'shortName': shortName,
    };
  }

  /// Convert a Subject into a Map.
  static Subject fromMap(Map<String, dynamic> map) {
    return Subject(name: map["name"], shortName: map["shortName"]);
  }
}
