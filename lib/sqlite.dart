import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pick and add image to database for the specified homework
/// Return true on success, otherwise false
Future<bool> pickAndAddImage(BuildContext context, Homework hw) async {
  bool takePhoto = Platform.isAndroid || Platform.isIOS || kDebugMode ? await _openChooseSourceBar(context) : false;
  XFile? xFile = await ImagePicker().pickImage(source: takePhoto ? ImageSource.camera : ImageSource.gallery);
  if (xFile == null) return false;
  HWPage page = await HWPage.readXFile(hw.id!, xFile);
  DBHelper().insertHWPage(page, orderIn: true);
  return true;
}

// TODO: Fix that this doesnt work on iOS/iPadOS
// TODO: Add permission_handler
Future<bool> _openChooseSourceBar(BuildContext context) async {
  return await showModalBottomSheet(
          context: context,
          builder: (BuildContext context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                        child: TextButton(
                      style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero
                            .copyWith(topLeft: const Radius.circular(30.0), topRight: const Radius.circular(30.0)),
                      )),
                      child: Row(
                        children: [
                          const SizedBox(width: 70),
                          const Icon(size: 50, Icons.add_a_photo_rounded),
                          Expanded(
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                      style: const TextStyle(fontSize: 25.0),
                                      AppLocalizations.of(context)!.photoOptionCamera)))
                        ],
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    )),
                    Expanded(
                        child: TextButton(
                      style: TextButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                      child: Row(
                        children: [
                          const SizedBox(width: 70),
                          const Icon(size: 50, Icons.add_photo_alternate_rounded),
                          Expanded(
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                      style: const TextStyle(fontSize: 25.0),
                                      AppLocalizations.of(context)!.photoOptionGallery)))
                        ],
                      ),
                      onPressed: () => Navigator.pop(context),
                    )),
                  ],
                ),
              )) ==
      true;
}

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
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    if (kDebugMode) {
      print("Saving/open database to/on ${join(appDocumentsDir.path, "hwm_databases", 'hw_database.db')}");
    }
    // Open the database and store the reference.
    db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(appDocumentsDir.path, "hwm_databases", 'hw_database.db'),
      onUpgrade: (db, oldVersion, newVersion) async {
        return await db.execute('CREATE TABLE imageBlobs('
            'id TEXT PRIMARY KEY, '
            'data BLOB NOT NULL'
            ')');
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE imageBlobs('
            'id TEXT PRIMARY KEY, '
            'data BLOB NOT NULL'
            ')');
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
    return Subject.fromMap((await db.query('subjects', where: "name = ?", whereArgs: [name]))[0]);
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
    final List<Map<String, Object?>> queryResult = await db.query('homeworks', orderBy: "overdueDate");
    return queryResult.map((e) => Homework.fromMap(e)).toList();
  }

  // Deletes homework from database. If homework does not have id, nothing will be deleted
  Future<List<void>> deleteHomework(Homework hw) async {
    return await Future.wait([deleteHomeworkById(hw.id ?? -1), deleteHWPagesByHW(hw)]);
  }

  Future<void> deleteHomeworkById(int id) async {
    await db.delete(
      'homeworks',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  /// Insert/update document with existing homework id
  Future<int> insertHWPage(HWPage page, {bool orderIn = false}) async {
    print("INSERT: ${page.order}");
    if (orderIn) page.order = await countHWPages(page.hwId);
    print("INSERT AFTER REORDER: ${page.order}");
    return await db.insert(
      'imageBlobs',
      await page.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> insertHWPages(List<HWPage> pages) async {
    return await Future.wait([for (HWPage page in pages) insertHWPage(page)]);
  }

  Future<int> countHWPages(int hwId) async {
    final List<Map<String, Object?>> queryResult =
        await db.query("imageBlobs", columns: ["COUNT(id)"], where: 'id LIKE ?', whereArgs: ["$hwId+%"]);
    if (queryResult[0]["COUNT(id)"] == null) return 0;
    return queryResult[0]["COUNT(id)"] as int;
  }

  Future<HWPage?> retrieveHWPage(Homework hw, int order) async {
    final List<Map<String, Object?>> queryResult =
        await db.query('imageBlobs', where: 'id = ?', whereArgs: ["${hw.id ?? "NULL"}+$order"]);
    if (queryResult.isEmpty) return null;
    return queryResult.map((e) => HWPage.fromMap(e)).toList()[0];
  }

  Future<List<HWPage>> retrieveHWPages(Homework hw) async {
    final List<Map<String, Object?>> queryResult =
        await db.query('imageBlobs', where: 'id LIKE ?', whereArgs: ["${hw.id ?? "NULL"}+%"]);
    if (queryResult.isEmpty) return [];
    var result = queryResult.map((e) => HWPage.fromMap(e)).toList();
    return result;
  }

  /// Deletes HWPage from database. If HWPage does not have id, nothing will be deleted
  Future<int> deleteHWPage(HWPage page) async {
    return await deleteHWPageByFullId("${page.hwId}+${page.order}");
  }

  Future<int> deleteHWPagesByHW(Homework hw) async {
    return await db.delete(
      'imageBlobs',
      where: "id LIKE ?",
      whereArgs: ["${hw.id}+%"],
    );
  }

  Future<List<void>> deleteHWPagesByHWOrder(Homework hw, List<int> order) async {
    for (int p in order) {
      print("DELET ${hw.id ?? -1}+$p");
      await db.delete(
        'imageBlobs',
        where: "id = ?",
        whereArgs: ["${hw.id}+$p"],
      );
    }
    return await reorderHWPages(hw);
  }

  Future<List<void>> reorderHWPages(Homework hw) async {
    List<HWPage> pages = await retrieveHWPages(hw);
    pages.sort((a, b) => a.order.compareTo(b.order));
    print("These are the currently existing pages: ${pages.map((e) => e.order)}");
    return await Future.wait([
      for (int i = 0; i < pages.length; i++)
        () async {
          HWPage p = pages[i];
          await deleteHWPage(p);
          p.order = i;
          await insertHWPage(p, orderIn: false);
        }()
    ]);
  }

  Future<int> deleteHWPageByHWOrder(Homework hw, int order) async {
    return await db.delete(
      'imageBlobs',
      where: "id = ?+?",
      whereArgs: [hw.id, order],
    );
  }

  Future<int> deleteAllHWPages() async {
    return await db.delete('imageBlobs');
  }

  Future<int> deleteHWPageByFullId(String id) async {
    return await db.delete(
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

class HWPage {
  /// The linked homework
  final int hwId;
  int order;
  Uint8List data;

  HWPage(this.hwId, this.data, {int? order}) : order = order ?? 0;

  static Future<HWPage> readXFile(int homeworkId, XFile xFile) async {
    return HWPage(homeworkId, await xFile.readAsBytes());
  }

  /// Convert a HWPage into a Map.
  Future<Map<String, Object?>> toMap() async {
    return {
      'id': "$hwId+$order",
      'data': data,
    };
  }

  /// Convert a HWPage into a Map.
  static HWPage fromMap(Map<String, Object?> map) {
    List<String> id = map["id"]!.toString().split("+");
    int hwID = int.parse(id[0]);
    int order = int.parse(id[1]);
    return HWPage(hwID, map["data"]! as Uint8List, order: order);
  }

  @override
  String toString() {
    return 'HWImage{id: $hwId+$order, data: ${data.length}';
  }
}
