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
  DBHelper.insertHWPage(page, orderIn: true);
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
    DBHelper().db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      kIsWeb
          ? "hw_database.db"
          : join((await getApplicationDocumentsDirectory()).path, "hwm_databases", 'hw_database.db'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          await db.execute('CREATE TABLE imageBlobs(id TEXT PRIMARY KEY, data BLOB NOT NULL)');
        }
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE discordRelations(channel TEXT PRIMARY KEY, webhook TEXT)');
        }
        if (oldVersion < 3) await db.execute("ALTER TABLE subjects ADD COLUMN discordChannel TEXT");
        if (oldVersion < 4) await db.execute("ALTER TABLE homeworks DROP COLUMN subject_short");
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE discordRelations ADD COLUMN channelID TEXT");
          await db.execute("ALTER TABLE discordRelations RENAME COLUMN channel to channelName");
          await db.execute("ALTER TABLE discordRelations RENAME TO orig_discordRelations"); // Hold data for later
          // orig_discordRelations(channelName TEXT PRIMARY KEY, webhook TEXT, channelID TEXT)
          await db.execute(
            'CREATE TABLE discordRelations(channelID TEXT PRIMARY KEY, channelName TEXT NOT NULL, webhook TEXT)',
          ); // Create table with correct PK
          await db.execute(
            'INSERT INTO discordRelations SELECT channelID, channelName, webhook FROM orig_discordRelations',
          );
          await db.execute("ALTER TABLE subjects RENAME COLUMN discordChannel to discordChannelID");
        }
        if (oldVersion < 6) {
          await db.execute("ALTER TABLE homeworks ADD COLUMN messageID TEXT");
        }
      },
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE discordRelations(channelID TEXT PRIMARY KEY, channelName TEXT NOT NULL, webhook TEXT)',
        );
        await db.execute('CREATE TABLE imageBlobs(id TEXT PRIMARY KEY, data BLOB NOT NULL)');
        await db.execute('CREATE TABLE subjects(name TEXT PRIMARY KEY, shortName TEXT, discordChannelID TEXT)');
        return db.execute("CREATE TABLE homeworks(id INTEGER PRIMARY KEY AUTOINCREMENT, "
            'subject TEXT NOT NULL, '
            'overdueDate TEXT NOT NULL, '
            'content TEXT NOT NULL, '
            'creationDate TEXT NOT NULL, '
            'finished TEXT NOT NULL, '
            'messageID TEXT)');
      },
      // VERSION 2 -- Added imageblobs table
      // VERSION 3 -- Added discord table
      // VERSION 4 -- Modified homeworks table
      // VERSION 5 -- Modified discord table to hold channelID & moved primary key and modified subject table
      // VERSION 6 -- Added messageID to homeworks table
      version: 6,
    );
    return true;
  }

  /// Inserts or edits subject supplied into database
  static Future<int> insertSubject(Subject subject) async {
    return DBHelper().db.insert('subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Subject?> getSubject(String name) async {
    final Map<String, Object?>? queryResult =
        (await DBHelper().db.query('subjects', where: "name = ?", whereArgs: [name])).firstOrNull;
    return queryResult != null
        ? Subject.fromMap(queryResult.map((key, value) => MapEntry(key, value.toString())))
        : null;
  }

  static Future<List<Subject>> retrieveSubjects() async {
    final List<Map<String, Object?>> queryResult = await DBHelper().db.query('subjects', orderBy: "name");
    return Future.wait(queryResult.map((e) => Subject.fromMap(e.map((key, value) => MapEntry(key, value.toString())))));
  }

  static Future<List<Subject>> retrieveSubjectsIn(String channelID) async {
    final List<Map<String, Object?>> queryResult =
        await DBHelper().db.query('subjects', where: "discordChannelID = ?", whereArgs: [channelID]);
    return Future.wait(queryResult.map((e) => Subject.fromMap(e.map((key, value) => MapEntry(key, value.toString())))));
  }

  static Future<void> deleteSubject(String name) async {
    await DBHelper().db.delete('subjects', where: "name = ?", whereArgs: [name]);
  }

  /// Inserts or replaces discord relation supplied into database
  static Future<int> insertDiscordRelation(DiscordRelation dr) async {
    return DBHelper().db.insert('discordRelations', dr.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<DiscordRelation?> getDiscordRelation(String channelID) async {
    final Map<String, Object?>? queryResult =
        (await DBHelper().db.query('discordRelations', where: "channelID = ?", whereArgs: [channelID])).firstOrNull;
    return queryResult != null ? DiscordRelation.fromMap(queryResult.map((k, v) => MapEntry(k, v.toString()))) : null;
  }

  static Future<DiscordRelation?> getDiscordRelationByWHID(String webhookID) async {
    final Map<String, Object?>? queryResult =
        (await DBHelper().db.query('discordRelations', where: "channelID LIKE '%?%'", whereArgs: [webhookID]))
            .firstOrNull;
    return queryResult != null ? DiscordRelation.fromMap(queryResult.map((k, v) => MapEntry(k, v.toString()))) : null;
  }

  static Future<List<DiscordRelation>> retrieveDiscordRelations() async {
    final List<Map<String, Object?>> queryResult =
        await DBHelper().db.query('discordRelations', orderBy: "channelName");
    return queryResult.map((e) => DiscordRelation.fromMap(e.map((k, v) => MapEntry(k, v.toString())))).toList();
  }

  static Future<void> deleteDiscordRelation(String channelID) async {
    await DBHelper().db.update('subjects', {"discordChannelID": ""}, where: "name = ?", whereArgs: [channelID]);
    await DBHelper().db.delete('discordRelations', where: "channelID = ?", whereArgs: [channelID]);
  }

  /// Inserts or updates homework supplied into database
  /// Returns the id of the homework
  static Future<int> insertHomework(Homework hw) async {
    return DBHelper().db.insert('homeworks', hw.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

// TODO Add search function/do not return the whole list of homeworks
  static Future<List<Homework>> retrieveHomeworks() async {
    final List<Map<String, Object?>> queryResult = await DBHelper().db.query('homeworks', orderBy: "overdueDate");
    final List<Homework> hws = await Future.wait(
      queryResult.map((e) => Homework.fromMap(e.map((key, value) => MapEntry(key, value.toString())))),
    );
    return hws;
  }

  static Future<Homework?> getHomeworkByMessageID(String messageID) async {
    final Map<String, Object?>? queryResult =
        (await DBHelper().db.query('homeworks', where: "messageID = ?", whereArgs: [messageID])).firstOrNull;
    return queryResult != null ? await Homework.fromMap(queryResult.map((k, v) => MapEntry(k, v.toString()))) : null;
  }

  // Deletes homework from database. If homework does not have id, nothing will be deleted
  static Future<List<void>> deleteHomework(Homework hw) async {
    return Future.wait([deleteHomeworkById(hw.id ?? -1), deleteHWPagesByHW(hw)]);
  }

  static Future<void> deleteHomeworkById(int id) async {
    await DBHelper().db.delete('homeworks', where: "id = ?", whereArgs: [id]);
  }

  /// Insert/update document with existing homework id
  static Future<int> insertHWPage(HWPage page, {bool orderIn = false}) async {
    if (kDebugMode) {
      print("INSERT: ${page.order}");
    }
    if (orderIn) page.order = await countHWPages(page.hwId);
    if (kDebugMode) {
      print("INSERT AFTER REORDER: ${page.order}");
    }
    return DBHelper().db.insert('imageBlobs', await page.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<int>> insertHWPages(List<HWPage> pages) async {
    return Future.wait([for (final HWPage page in pages) insertHWPage(page)]);
  }

  static Future<int> countHWPages(int hwId) async {
    final List<Map<String, Object?>> queryResult =
        await DBHelper().db.query("imageBlobs", columns: ["COUNT(id)"], where: 'id LIKE ?', whereArgs: ["$hwId+%"]);
    if (queryResult[0]["COUNT(id)"] == null) return 0;
    return queryResult[0]["COUNT(id)"]! as int;
  }

  static Future<HWPage?> retrieveHWPage(Homework hw, int order) async {
    final List<Map<String, Object?>> queryResult =
        await DBHelper().db.query('imageBlobs', where: 'id = ?', whereArgs: ["${hw.id ?? "NULL"}+$order"]);
    if (queryResult.isEmpty) return null;
    return queryResult.map((e) => HWPage.fromMap(e)).toList()[0];
  }

  static Future<List<HWPage>> retrieveHWPages(Homework hw) async {
    final List<Map<String, Object?>> queryResult =
        await DBHelper().db.query('imageBlobs', where: 'id LIKE ?', whereArgs: ["${hw.id ?? "NULL"}+%"]);
    if (queryResult.isEmpty) return [];
    final result = queryResult.map((e) => HWPage.fromMap(e)).toList();
    result.sort((a, b) => a.order - b.order);
    return result;
  }

  /// Deletes HWPage from database. If HWPage does not have id, nothing will be deleted
  static Future<int> deleteHWPage(HWPage page) async {
    return deleteHWPageByFullId("${page.hwId}+${page.order}");
  }

  static Future<int> deleteHWPagesByHW(Homework hw) async {
    return DBHelper().db.delete('imageBlobs', where: "id LIKE ?", whereArgs: ["${hw.id}+%"]);
  }

  static Future<List<void>> deleteHWPagesByHWOrder(Homework hw, List<int> order) async {
    for (final int p in order) {
      if (kDebugMode) {
        print("DELET ${hw.id ?? -1}+$p");
      }
      await DBHelper().db.delete('imageBlobs', where: "id = ?", whereArgs: ["${hw.id}+$p"]);
    }
    return reorderHWPages(hw);
  }

  static Future<List<void>> reorderHWPages(Homework hw) async {
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

  static Future<int> deleteHWPageByHWOrder(Homework hw, int order) async {
    return DBHelper().db.delete('imageBlobs', where: "id = ?+?", whereArgs: [hw.id, order]);
  }

  static Future<int> deleteAllHWPages() async => DBHelper().db.delete('imageBlobs');

  static Future<int> deleteHWPageByFullId(String id) async =>
      DBHelper().db.delete('imageBlobs', where: "id = ?", whereArgs: [id]);
}

class Homework {
  int? id;
  final DateTime overdueTimestamp;
  final DateTime creationTimestamp;
  final Subject subject;
  final String content;
  final bool finished;
  String? messageID;

  bool get published => messageID != null;

  // DateTime needs DateTime.tryParse(isoString);
  Homework({
    this.id,
    required this.subject,
    required this.overdueTimestamp,
    required this.creationTimestamp,
    required this.content,
    required this.finished,
    this.messageID,
  });

  /// Convert a Homework into a Map.
  static Future<Homework> fromMap(Map<String, String?> map) async {
    final Homework hw = Homework(
      id: int.parse(map["id"]!),
      subject: await DBHelper.getSubject(map["subject"]!) ?? Subject(name: map["subject"]!),
      overdueTimestamp: DateTime.parse(map["overdueDate"]!),
      creationTimestamp: DateTime.parse(map["overdueDate"]!),
      content: map["content"]!,
      finished: bool.parse(map["finished"]!),
      messageID: map["messageID"] ?? "",
    );
    return hw;
  }

  /// Convert a Homework into a Map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subject': subject.name,
      'overdueDate': overdueTimestamp.toIso8601String(),
      'creationDate': creationTimestamp.toIso8601String(),
      'content': content,
      'finished': finished.toString(), // TODO: Implement this functionality
      'messageID': messageID ?? "",
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
  final DiscordRelation? discordChannel;

  const Subject({required this.name, this.shortName, this.discordChannel});

  /// Convert a Subject into a Map.
  static Future<Subject> fromMap(Map<String, String?> map) async {
    DiscordRelation? dr;
    if (map["discordChannelID"] != null && map["discordChannelID"] != "null") {
      dr = await DBHelper.getDiscordRelation(map["discordChannelID"]!);
      if (dr == null) {
        if (kDebugMode) {
          print("DATABASE ERROR ${map["discordChannelID"]} doesn't exist");
        }
      }
      // Subject points to channelid that isnt in realtion database, so ERROR
    }
    return Subject(
      name: map["name"]!,
      shortName: map["shortName"],
      discordChannel: dr,
    );
  }

  /// Convert a Subject into a Map.
  Map<String, Object?> toMap() {
    return {
      'name': name,
      'shortName': shortName ?? "",
      'discordChannelID': discordChannel?.channelID,
    };
  }

  @override
  bool operator ==(Object b) =>
      b is Subject && name == b.name && shortName == b.shortName && discordChannel == b.discordChannel;

  @override
  int get hashCode => Object.hash(name, shortName, discordChannel);
}

class DiscordRelation {
  final String channelName;
  final String channelID;
  final String? webhookUrl;

  const DiscordRelation({required this.channelID, required this.channelName, this.webhookUrl});

  /// Convert a DiscordRelation into a Map.https://discord.com/api/webhooks/1160945067184377996/E0dFr2laboRG2XO8ExVS0PYO7y7hhK5DWTsPf5wj52FOG3nyga6gS9fQ0l7TrxH6TwOW
  DiscordRelation.fromMap(Map<String, String?> map)
      : channelID = map["channelID"]!,
        channelName = map["channelName"]!,
        webhookUrl = map["webhook"];

  /// Convert a DiscordRelation into a Map.
  Map<String, Object?> toMap() {
    return {
      'channelID': channelID,
      'channelName': channelName,
      'webhook': webhookUrl ?? "",
    };
  }

  @override
  bool operator ==(Object b) =>
      b is DiscordRelation &&
      channelID == b.channelID &&
      channelName == b.channelName &&
      webhookUrl.toString() == b.webhookUrl.toString();

  @override
  int get hashCode => Object.hash(channelID, channelName, webhookUrl);
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
