import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hw_manager_flutter/general_util.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';

void Function(String text) untisError = (String text) =>
    HWMToast(text: text, color: Colors.redAccent.withOpacity(0.8), icon: const Icon(Icons.access_time_rounded)).show();
void Function(String text) untisConfirmation = (String text) =>
    HWMToast(text: text, color: Colors.green.shade900, icon: const Icon(Icons.access_time_rounded)).show();

class UntisHelper {
  static final UntisHelper _untisHelper = UntisHelper._();

  factory UntisHelper() {
    return _untisHelper;
  }

  UntisHelper._();

  UntisSession? session;

  Future<bool> login(
    String? server,
    String? school,
    String? username,
    String? password,
  ) async {
    if (server == null) return false;
    if (school == null) return false;
    if (username == null) return false;
    if (password == null) return false;
    if (kDebugMode) {
      print("$server $school");
    }
    try {
      session = await UntisSession.init(server, school, username, password);
    } on Exception {
      session = null;
      return false;
    }
    return true;
  }

  Future<bool> get loginCredentialsValid async {
    final String? server = await Preferences.getUntisServer();
    final String? school = await Preferences.getUntisSchool();
    final String? username = await Preferences.getUntisUsername();
    final String? password = await Preferences.getUntisPassword();
    final List<String?> credentials = [server, school, username, password];
    for (final String? s in credentials) {
      if (s == null) return false;
      if (s.isEmpty) return false;
      if (s.length < 2) return false;
    }
    if (!server!.contains("untis.com")) return false;
    return true;
  }

  Future<bool> loginWithPreferences() async {
    final String? server = await Preferences.getUntisServer();
    final String? school = await Preferences.getUntisSchool();
    final String? username = await Preferences.getUntisUsername();
    final String? password = await Preferences.getUntisPassword();
    return UntisHelper().login(server, school, username, password);
  }

  Future<List<UntisSubject>?> getUntisSubjects() async {
    if (session == null) {
      final bool success = await loginWithPreferences();
      if (!success) {
        session = null;
        return null;
      }
    }
    return session!.subjects;
  }

  Future<List<UntisSubject>> getCurrentUntisSubjects() async {
    if (session == null) {
      final bool success = await loginWithPreferences();
      if (!success) throw ArgumentError("Still couldn't login");
    }
    _cachedSubjects ??= await session!.getCurrentSubjects();
    return _cachedSubjects!;
  }

  List<UntisSubject>? _cachedSubjects;

  Future<UntisSubject?> searchUntisSubject(
    String longName, [
    String? shortName,
  ]) async {
    if (shortName != null) {
      if (kDebugMode) print("Out there are: ${(await getCurrentUntisSubjects()).map((e) => e.longName)}");
      return (await getCurrentUntisSubjects())
          .where(
            (element) => element.name.toLowerCase().trim().startsWith(shortName.toLowerCase().trim()),
          )
          .firstOrNull;
    }
    return (await getCurrentUntisSubjects())
        .where(
          (element) => element.longName.toLowerCase().trim().contains(longName.toLowerCase().trim()),
        )
        .firstOrNull;
  }

  Future<UntisPeriod?> searchUntisSubjectUntisPeriod(
    UntisSubject subject, {
    int maxSteps = 8,
    int searchIntervalsInDays = 8,
  }) async =>
      (await searchUntisSubjectUntisPeriods(subject)).firstOrNull;

  Future<List<UntisPeriod>> searchUntisSubjectUntisPeriods(
    UntisSubject subject, {
    bool cancelled = false,
    int maxAmount = 1,
    int maxSteps = 8,
    int searchIntervalsInDays = 8,
  }) async {
    final List<UntisPeriod> foundUntisPeriods = [];
    for (int i = 0; i < maxSteps && foundUntisPeriods.length < maxAmount; i++) {
      if (kDebugMode) {
        print("Step $i");
      }
      final DateTime stepStart = DateTime.timestamp();
      // TODO: Implement cache, so the fetching would be faster
      Iterable<UntisPeriod> timetable = (await session!.getTimetable(
        id: (await session!.studentData).id,
        startDate: i == 0
            ? DateTime.now().add(const Duration(days: 1))
            : DateTime.now().add(Duration(days: searchIntervalsInDays * i)),
        endDate: DateTime.now().add(Duration(days: searchIntervalsInDays * (i + 1))),
      ))
          .periods;
      if (kDebugMode) {
        print(
          "Just getting timetable: ${DateTime.timestamp().difference(stepStart).inMilliseconds}ms for ${DateTime.now().add(Duration(days: searchIntervalsInDays * (i + 1))).difference(i == 0 ? DateTime.now().add(const Duration(days: 1)) : DateTime.now().add(Duration(days: searchIntervalsInDays * i))).inDays}d",
        );
      }
      timetable = timetable.where((element) => element.subjects.isNotEmpty);
      if (cancelled == false) {
        timetable = timetable.where((element) => element.isCancelled == false);
      }
      foundUntisPeriods.addAll(
        timetable.where((element) => element.subjects.contains(subject)),
      );
    }
    return foundUntisPeriods;
  }
}
