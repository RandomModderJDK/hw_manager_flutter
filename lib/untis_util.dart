import 'dart:io';

import 'package:dart_webuntis/untis.dart';
import 'package:flutter/foundation.dart';
import 'package:hw_manager_flutter/shared_preferences.dart';

class UntisHelper {
  static final UntisHelper _untisHelper = UntisHelper._();

  factory UntisHelper() {
    return _untisHelper;
  }

  UntisHelper._();

  Session? session;

  Future<bool> login(
    String server,
    String school,
    String username,
    String password,
  ) async {
    print("$server $school $username $password");
    try {
      session = await Session.init(server, school, username, password);
    } on HttpException {
      return false;
    }
    if (session == null) return false;
    final IdProvider? myID = session!.userId;
    return myID != null;
  }

  Future<bool> loginWithPreferences() async {
    final String? server = await Preferences.getUntisServer();
    final String? school = await Preferences.getUntisSchool();
    final String? username = await Preferences.getUntisUsername();
    final String? password = await Preferences.getUntisPassword();
    if (server == null) return false;
    if (school == null) return false;
    if (username == null) return false;
    if (password == null) return false;
    return UntisHelper().login(server, school, username, password);
  }

  Future<List<Subject>> getSubjects() async {
    if (session == null) {
      final bool success = await loginWithPreferences();
      if (!success) return [];
    }
    return session!.getSubjects();
  }

  Future<List<Subject>> getCurrentSubjects() async {
    if (session == null) {
      final bool success = await loginWithPreferences();
      if (!success) return [];
    }
    final List<Subject> subjects = await session!.getSubjects();
    final List<Period> periods = await session!.getTimetable(
      session!.userId!,
      endDate: DateTime.now().add(const Duration(days: 128)),
    );
    final Iterable<IdProvider> subjectIds = periods.expand((e) => e.subjectIds);
    return subjects.where((element) => subjectIds.contains(element.id)).toList();
  }

  Future<Subject?> searchSubject(String longName, [String? shortName]) async {
    if (session == null) {
      final bool success = await loginWithPreferences();
      if (!success) return null;
    }
    if (shortName != null) {
      return (await session!.getSubjects())
          .where(
            (element) => element.name.toLowerCase().trim().startsWith(shortName.toLowerCase().trim()),
          )
          .firstOrNull;
    }
    return (await session!.getSubjects())
        .where(
          (element) => element.longName.toLowerCase().trim().contains(longName.toLowerCase().trim()),
        )
        .firstOrNull;
  }

  Future<Period?> searchSubjectPeriod(
    Subject subject, {
    int maxSteps = 8,
    int searchIntervalsInDays = 8,
  }) async =>
      (await searchSubjectPeriods(subject)).firstOrNull;

  Future<List<Period>> searchSubjectPeriods(
    Subject subject, {
    bool cancelled = false,
    int maxAmount = 1,
    int maxSteps = 8,
    int searchIntervalsInDays = 8,
  }) async {
    final List<Period> foundPeriods = [];
    for (int i = 0; i < maxSteps && foundPeriods.length < maxAmount; i++) {
      if (kDebugMode) {
        print("Step $i");
      }
      Iterable<Period> timetable = await session!.getTimetable(
        session!.userId!,
        startDate: i == 0
            ? DateTime.now().add(const Duration(days: 1))
            : DateTime.now().add(Duration(days: searchIntervalsInDays * i)),
        endDate: DateTime.now().add(Duration(days: searchIntervalsInDays * (i + 1))),
      );
      timetable = timetable.where((element) => element.subjectIds.isNotEmpty);
      if (cancelled == false) {
        timetable = timetable.where((element) => element.isCancelled == false);
      }
      foundPeriods.addAll(
        timetable.where((element) => element.subjectIds.contains(subject.id)),
      );
    }
    return foundPeriods;
  }
}
