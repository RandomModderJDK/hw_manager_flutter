import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Pick and add image to database for the specified homework
/// Return true on success, otherwise false
Future<bool> pickAndAddImage(BuildContext context, Homework hw) async {
  ImageSource? imageSource = ImageSource.gallery;
  if (Platform.isAndroid || Platform.isIOS || kDebugMode) {
    imageSource = await _openChooseSourceBar(context);
    // If user decides to select nothing, the dialog will get closed.
    if (imageSource == null) return false;
  }

  final XFile? xFile = await ImagePicker().pickImage(source: imageSource);
  if (xFile == null) return false;
  final HWPage page = await HWPage.readXFile(hw.id!, xFile);
  DBHelper().insertHWPage(page, orderIn: true);
  return true;
}

Future<ImageSource?> _openChooseSourceBar(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => ListView(
      shrinkWrap: true,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 40.00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero
                      .copyWith(topLeft: const Radius.circular(30.0), topRight: const Radius.circular(30.0)),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 70),
                  const Icon(size: 50, Icons.add_a_photo_rounded),
                  Expanded(
                    child: Align(
                      child: Text(
                        style: const TextStyle(fontSize: 25.0),
                        context.locals.photoOptionCamera,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () => Navigator.pop(context, ImageSource.camera),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 40.00),
                shape: const RoundedRectangleBorder(),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 70),
                  const Icon(size: 50, Icons.add_photo_alternate_rounded),
                  Expanded(
                    child: Align(
                      child: Text(
                        style: const TextStyle(fontSize: 25.0),
                        context.locals.photoOptionGallery,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ],
    ),
  );
}

// TODO Add search function/do not return the whole list of homeworks
class DBHelper {
  static final DBHelper _dbHelper = DBHelper._();

  factory DBHelper() {
    return _dbHelper;
  }

  DBHelper._();

  late Database db;

  Future<bool> initDBs() async {
    if (kIsWeb) {
      // Change default factory on the web
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Avoid errors caused by flutter upgrade.
    // Importing 'package:flutter/widgets.dart' is required.
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      if (kDebugMode) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        print("Saving/open database to/on ${join(appDocumentsDir.path, "hwm_databases", 'hw_database.db')}");
      }
    }
    // Open the database and store the reference.
    db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      kIsWeb
          ? "hw_database.db"
          : join((await getApplicationDocumentsDirectory()).path, "hwm_databases", 'hw_database.db'),
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('CREATE TABLE discordRelations(channel TEXT PRIMARY KEY, webhook TEXT)');
        await db.execute("ALTER TABLE subjects ADD COLUMN discordChannel TEXT");
        if (oldVersion == 1) await db.execute('CREATE TABLE imageBlobs(id TEXT PRIMARY KEY, data BLOB NOT NULL)');
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE discordRelations(channel TEXT PRIMARY KEY, webhook TEXT)');
        await db.execute('CREATE TABLE imageBlobs(id TEXT PRIMARY KEY, data BLOB NOT NULL)');
        await db.execute('CREATE TABLE subjects(name TEXT PRIMARY KEY, shortName TEXT, discordChannel TEXT)');
        return db.execute("CREATE TABLE homeworks(id INTEGER PRIMARY KEY AUTOINCREMENT, "
            'subject_short TEXT, '
            'subject TEXT NOT NULL, '
            'overdueDate TEXT NOT NULL, '
            'content TEXT NOT NULL, '
            'creationDate TEXT NOT NULL, '
            'finished TEXT NOT NULL)');
      },
      // VERSION 2 -- Added imageblobs table
      // VERSION 3 -- Added discord table
      version: 3,
    );
    return true;
  }

  /// Inserts or edits subject supplied into database
  Future<int> insertSubject(Subject subject) async {
    return db.insert('subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Subject?> getSubject(String name) async {
    return Subject.fromMap((await db.query('subjects', where: "name = ?", whereArgs: [name]))[0]);
  }

  Future<List<Subject>> retrieveSubjects() async {
    final List<Map<String, Object?>> queryResult = await db.query('subjects', orderBy: "name");
    return queryResult.map((e) => Subject.fromMap(e)).toList();
  }

  Future<void> deleteSubject(String name) async {
    await db.delete('subjects', where: "name = ?", whereArgs: [name]);
  }

  /// Inserts or replaces discord relation supplied into database
  Future<int> insertDiscordRelation(DiscordRelation dr) async {
    return db.insert('discordRelations', dr.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DiscordRelation?> getDiscordRelation(String channelName) async {
    return DiscordRelation.fromMap(
      (await db.query('discordRelations', where: "channel = ?", whereArgs: [channelName]))[0]
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<List<DiscordRelation>> retrieveDiscordRelations() async {
    final List<Map<String, Object?>> queryResult = await db.query('discordRelations', orderBy: "channel");
    return queryResult.map((e) => DiscordRelation.fromMap(e.map((k, v) => MapEntry(k, v.toString())))).toList();
  }

  Future<void> deleteDiscordRelation(String channelName) async {
    await db.delete('discordRelations', where: "channel = ?", whereArgs: [channelName]);
  }

  /// Inserts or updates homework supplied into database
  Future<int> insertHomework(Homework hw) async {
    return db.insert('homeworks', hw.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Homework>> retrieveHomeworks() async {
    final List<Map<String, Object?>> queryResult = await db.query('homeworks', orderBy: "overdueDate");
    return queryResult.map((e) => Homework.fromMap(e.map((key, value) => MapEntry(key, value.toString())))).toList();
  }

  // Deletes homework from database. If homework does not have id, nothing will be deleted
  Future<List<void>> deleteHomework(Homework hw) async {
    return Future.wait([deleteHomeworkById(hw.id ?? -1), deleteHWPagesByHW(hw)]);
  }

  Future<void> deleteHomeworkById(int id) async {
    await db.delete('homeworks', where: "id = ?", whereArgs: [id]);
  }

  /// Insert/update document with existing homework id
  Future<int> insertHWPage(HWPage page, {bool orderIn = false}) async {
    if (kDebugMode) {
      print("INSERT: ${page.order}");
    }
    if (orderIn) page.order = await countHWPages(page.hwId);
    if (kDebugMode) {
      print("INSERT AFTER REORDER: ${page.order}");
    }
    return db.insert('imageBlobs', await page.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<int>> insertHWPages(List<HWPage> pages) async {
    return Future.wait([for (final HWPage page in pages) insertHWPage(page)]);
  }

  Future<int> countHWPages(int hwId) async {
    final List<Map<String, Object?>> queryResult =
        await db.query("imageBlobs", columns: ["COUNT(id)"], where: 'id LIKE ?', whereArgs: ["$hwId+%"]);
    if (queryResult[0]["COUNT(id)"] == null) return 0;
    return queryResult[0]["COUNT(id)"]! as int;
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
    final result = queryResult.map((e) => HWPage.fromMap(e)).toList();
    return result;
  }

  /// Deletes HWPage from database. If HWPage does not have id, nothing will be deleted
  Future<int> deleteHWPage(HWPage page) async {
    return deleteHWPageByFullId("${page.hwId}+${page.order}");
  }

  Future<int> deleteHWPagesByHW(Homework hw) async {
    return db.delete('imageBlobs', where: "id LIKE ?", whereArgs: ["${hw.id}+%"]);
  }

  Future<List<void>> deleteHWPagesByHWOrder(Homework hw, List<int> order) async {
    for (final int p in order) {
      if (kDebugMode) {
        print("DELET ${hw.id ?? -1}+$p");
      }
      await db.delete('imageBlobs', where: "id = ?", whereArgs: ["${hw.id}+$p"]);
    }
    return reorderHWPages(hw);
  }

  Future<List<void>> reorderHWPages(Homework hw) async {
    final List<HWPage> pages = await retrieveHWPages(hw);
    pages.sort((a, b) => a.order.compareTo(b.order));
    if (kDebugMode) {
      print("These are the currently existing pages: ${pages.map((e) => e.order)}");
    }
    return Future.wait([
      for (int i = 0; i < pages.length; i++)
        () async {
          final HWPage p = pages[i];
          await deleteHWPage(p);
          p.order = i;
          await insertHWPage(p);
        }(),
    ]);
  }

  Future<int> deleteHWPageByHWOrder(Homework hw, int order) async {
    return db.delete('imageBlobs', where: "id = ?+?", whereArgs: [hw.id, order]);
  }

  Future<int> deleteAllHWPages() async => db.delete('imageBlobs');

  Future<int> deleteHWPageByFullId(String id) async => db.delete('imageBlobs', where: "id = ?", whereArgs: [id]);
}

class Homework {
  final int? id;
  final DateTime overdueTimestamp;
  final DateTime creationTimestamp;
  final Subject subject;
  final String content;
  final bool finished;

  // DateTime needs DateTime.tryParse(isoString);
  const Homework({
    this.id,
    required this.subject,
    required this.overdueTimestamp,
    required this.creationTimestamp,
    required this.content,
    required this.finished,
  });

  /// Convert a Homework into a Map.
  Homework.fromMap(Map<String, String?> map)
      : id = int.parse(map["id"]!),
        subject = Subject(name: map["subject"]!, shortName: map["subject_short"]),
        overdueTimestamp = DateTime.parse(map["overdueDate"]!),
        creationTimestamp = DateTime.parse(map["overdueDate"]!),
        content = map["content"]!,
        finished = bool.parse(map["finished"]!);

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

  @override
  String toString() {
    return 'Homework{id: $id, subject: ${subject.name}, overdue at: ${overdueTimestamp.toIso8601String()} content: $content}';
  }
}

class Subject {
  final String name;
  final String? shortName;
  final String? discordChannel;

  const Subject({required this.name, this.shortName, this.discordChannel});

  /// Convert a Subject into a Map.
  Subject.fromMap(Map<String, Object?> map)
      : name = map["name"].toString(),
        shortName = map["shortName"].toString(),
        discordChannel = map["discordChannel"].toString();

  /// Convert a Subject into a Map.
  Map<String, Object?> toMap() {
    return {
      'name': name,
      'shortName': shortName,
      'discordChannel': discordChannel,
    };
  }
}

class DiscordRelation {
  final String channelName;
  final String? webhookUrl;

  const DiscordRelation({required this.channelName, this.webhookUrl});

  /// Convert a DiscordRelation into a Map.
  DiscordRelation.fromMap(Map<String, String?> map)
      : channelName = map["channel"]!,
        webhookUrl = map["webhook"];

  /// Convert a DiscordRelation into a Map.
  Map<String, Object?> toMap() {
    return {
      'channel': channelName,
      'webhook': webhookUrl,
    };
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
  HWPage.fromMap(Map<String, Object?> map)
      : hwId = getHwIdFromId(map["id"].toString()),
        order = getOrderFromId(map["id"].toString()),
        data = map["data"]! as Uint8List;

  static int getHwIdFromId(String hwPageId) {
    final List<String> id = hwPageId.split("+");
    return int.parse(id[0]);
  }

  static int getOrderFromId(String hwPageId) {
    final List<String> id = hwPageId.split("+");
    return int.parse(id[1]);
  }

  /// Convert a HWPage into a Map.
  Future<Map<String, Object?>> toMap() async {
    return {
      'id': "$hwId+$order",
      'data': data,
    };
  }

  @override
  String toString() {
    return 'HWImage{id: $hwId+$order, data: ${data.length}';
  }
}
