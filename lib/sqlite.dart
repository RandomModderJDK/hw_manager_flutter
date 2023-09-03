import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
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
          "Saving/open database to/on ${join(appDocumentsDir.path, "hwm_databases", 'hw_database.db')}");
    }
    // Open the database and store the reference.
    db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(appDocumentsDir.path, "hwm_databases", 'hw_database.db'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          return db.execute('CREATE TABLE imageBlobs('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'homeworkId INTEGER NOT NULL, '
              'orderId INTEGER NOT NULL, '
              'data BLOB NOT NULL'
              ')');
        }
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE subjects('
            'name TEXT PRIMARY KEY, '
            'shortName TEXT '
            ')');
        await db.execute('CREATE TABLE imageBlobs('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'homeworkId INTEGER NOT NULL, '
            'orderId INTEGER NOT NULL, '
            'data BLOB NOT NULL'
            ')');
        return db.execute('CREATE TABLE homeworks('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'subject_short TEXT, '
            'subject TEXT NOT NULL, '
            'overdueDate TEXT NOT NULL, '
            'content TEXT NOT NULL, '
            'creationDate TEXT NOT NULL, '
            'finished TEXT NOT NULL'
            ')');
      },
      // VERSION 2 -- Added imageblobs table
      version: 2,
    );
    return true;
  }

  /// Inserts or edits subject supplied into database
  Future<int> insertSubject(Subject subject) async {
    return await db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Subject?> getSubject(String name) async {
    return Subject.fromMap(
        (await db.query('subjects', where: "name = ?", whereArgs: [name]))[0]);
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

  /// Insert or update picture(s) from existing homework id
  Future<int> insertHWImage(HWImage hwImage) async {
    int orderId;
    if (hwImage.order == null) {
      List<int> order = await _retrieveHWImageOrder(hwImage.homeworkId);
      order.add(0); // The default ordering number i.e. the first photo
      order.sort();
      orderId = order[order.length - 1] + 1;
    } else {
      orderId = hwImage.order!;
    }
    return await db.insert(
      'imageBlobs',
      hwImage.toMap(orderId: orderId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HWImage>> retrieveHWImages(Homework hw) async {
    return await retrieveHWImagesById(hw.id);
  }

  /// -1 Stands for wildcard
  Future<List<HWImage>> retrieveHWImagesById(int? id) async {
    if (id == -1) {
      final List<Map<String, Object?>> queryResult =
          await db.query('imageBlobs');
      return queryResult.map((e) => HWImage.fromMap(e)).toList();
    }
    final List<Map<String, Object?>> queryResult = await db.query('imageBlobs',
        orderBy: "orderId", where: 'homeworkId = ?', whereArgs: [id ?? "NULL"]);
    return queryResult.map((e) => HWImage.fromMap(e)).toList();
  }

  Future<List<int>> _retrieveHWImageOrder(int? hwId) async {
    final List<Map<String, Object?>> queryResult = await db.query('imageBlobs',
        columns: ["orderId"],
        orderBy: "orderId",
        where: 'homeworkId = ?',
        whereArgs: [hwId ?? "NULL"]);
    return queryResult.map((e) => e["orderId"] as int).toList();
  }

  /// Deletes HWImage from database. If HWImage does not have id, nothing will be deleted
  Future<void> deleteHWImage(HWImage hw) async {
    return await deleteHomeworkById(hw.id ?? -1);
  }

  Future<void> deleteHWImageById(int id) async {
    await db.delete(
      'imageBlobs',
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
      'finished': finished.toString(),
    };
  }

  /// Convert a Homework into a Map.
  static Homework fromMap(Map<String, dynamic> map) {
    return Homework(
        id: map["id"],
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

class HWImage {
  /// The Image own ID
  final int? id;

  /// The linked homework
  final int homeworkId;

  /// Specifies which image is "page 1", etc.
  final int? order;
  final Uint8List data;

  const HWImage(this.homeworkId, this.data, {this.id, this.order});

  static Future<HWImage> readXFile(int homeworkId, XFile xFile,
      {int? id, int? order}) async {
    return HWImage(homeworkId, await xFile.readAsBytes(), id: id, order: order);
  }

  /// Convert a HWImage into a Map.
  Map<String, Object?> toMap({int? orderId}) {
    return {
      'id': id,
      'homeworkId': homeworkId,
      'orderId': orderId ?? order,
      'data': data,
    };
  }

  /// Convert a HWImage into a Map.
  static HWImage fromMap(Map<String, dynamic> map) {
    return HWImage(map["homeworkId"], map["data"] as Uint8List,
        id: map["id"], order: map["orderId"]);
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'HWImage{id: $id, homeworkId: $homeworkId, orderId: $order, data_len: ${data.length}';
  }
}
