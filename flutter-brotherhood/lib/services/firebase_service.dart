import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/task.dart';
import '../models/member.dart';
import '../models/profile.dart';
import '../models/progress_photo.dart';
import '../models/streak_info.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String get todayKey => dateKey(DateTime.now());

  /// A date is locked when it is before today.
  static bool isDateLocked(String date) {
    final today = todayKey;
    return date.compareTo(today) < 0;
  }

  /// Which challenge week (1-based) [date] falls into, relative to the
  /// challenge start date. Returns 0 if before the challenge starts.
  static int weekNumberFor(DateTime date) {
    final start = AppConstants.challengeStart;
    if (date.isBefore(start)) return 0;
    final days = date.difference(start).inDays;
    return (days ~/ AppConstants.progressPhotoIntervalDays) + 1;
  }

  // ── Tasks config ──────────────────────────────────────────────────────────

  CollectionReference get _tasksCol => _db.collection('tasks_config');

  Future<List<DailyTask>> fetchTasks() async {
    final snap = await _tasksCol.orderBy('order').get();
    if (snap.docs.isEmpty) {
      await seedDefaultTasks();
      return DailyTask.defaults;
    }
    final tasks = snap.docs
        .map((d) => DailyTask.fromMap(d.data() as Map<String, dynamic>))
        .toList();
    // Bring existing (possibly legacy) task configs in line with the new
    // per-member task rules without ever deleting data.
    await migrateTasksIfNeeded(tasks);
    return tasks;
  }

  Stream<List<DailyTask>> tasksStream() {
    return _tasksCol.orderBy('order').snapshots().map((snap) {
      if (snap.docs.isEmpty) return DailyTask.defaults;
      return snap.docs
          .map((d) => DailyTask.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> seedDefaultTasks() async {
    final batch = _db.batch();
    final defaults = DailyTask.defaults;
    for (int i = 0; i < defaults.length; i++) {
      final task = defaults[i];
      final ref = _tasksCol.doc(task.id);
      batch.set(ref, {...task.toMap(), 'order': i});
    }
    await batch.commit();
  }

  /// One-time, additive migration that upgrades an existing (legacy)
  /// tasks_config collection to match the new per-member task rules.
  /// Never deletes a document — only merges fields or adds missing ones —
  /// so historical completion data tied to old task ids stays intact.
  Future<void> migrateTasksIfNeeded(List<DailyTask> existing) async {
    final existingIds = existing.map((t) => t.id).toSet();
    final batch = _db.batch();
    bool changed = false;

    const vanshOnlyTitles = [
      '3 adequate meals',
      'eat dry fruits',
      'business',
      'looksmaxing',
      'pray be calm be kind',
      'study',
      'coding',
      'shoulder workout',
    ];

    // 1. Legacy "Learn Spanish" -> "Learn French", scoped to Vansh.
    for (final t in existing) {
      if (t.title.toLowerCase().contains('spanish')) {
        batch.set(
          _tasksCol.doc(t.id),
          {'title': 'Learn French', 'icon': '🇫🇷', 'appliesTo': ['vansh']},
          SetOptions(merge: true),
        );
        changed = true;
      }
    }

    // 2. Scope known Vansh-only tasks away from Govind & Piyush.
    for (final t in existing) {
      if (vanshOnlyTitles.contains(t.title.toLowerCase()) &&
          (t.appliesTo == null || t.appliesTo!.isEmpty)) {
        batch.set(
          _tasksCol.doc(t.id),
          {'appliesTo': ['vansh']},
          SetOptions(merge: true),
        );
        changed = true;
      }
    }

    // 3. Split a legacy single "water" task into per-member targets.
    final waterIdx = existing.indexWhere(
        (t) => t.id == 'drink_water' || t.title.toLowerCase().contains('water'));
    if (waterIdx != -1 && !existingIds.contains('water_gp')) {
      final t = existing[waterIdx];
      if (t.appliesTo == null || t.appliesTo!.isEmpty) {
        batch.set(
          _tasksCol.doc(t.id),
          {'title': 'Drink Water (5L)', 'appliesTo': ['vansh']},
          SetOptions(merge: true),
        );
        batch.set(_tasksCol.doc('water_gp'), {
          'id': 'water_gp',
          'title': 'Drink Water (4L)',
          'icon': '💧',
          'notificationTime': t.notificationTime,
          'isDefault': true,
          'appliesTo': ['govind', 'piyush'],
          'order': 100,
        });
        changed = true;
      }
    }

    // 4. Add any canonical tasks that are entirely missing.
    for (int i = 0; i < DailyTask.defaults.length; i++) {
      final canon = DailyTask.defaults[i];
      if (!existingIds.contains(canon.id) && canon.id != 'water_gp') {
        batch.set(
          _tasksCol.doc(canon.id),
          {...canon.toMap(), 'order': 200 + i},
          SetOptions(merge: true),
        );
        changed = true;
      }
    }

    if (changed) await batch.commit();
  }

  Future<void> saveTask(DailyTask task, int order) async {
    await _tasksCol.doc(task.id).set({...task.toMap(), 'order': order});
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCol.doc(taskId).delete();
  }

  Future<void> reorderTasks(List<DailyTask> tasks) async {
    final batch = _db.batch();
    for (int i = 0; i < tasks.length; i++) {
      batch.update(_tasksCol.doc(tasks[i].id), {'order': i});
    }
    await batch.commit();
  }

  // ── Day records ───────────────────────────────────────────────────────────

  DocumentReference _dayRecordDoc(String date) =>
      _db.collection('day_records').doc(date);

  /// Seeds the daily checklist for every member for [date], using each
  /// member's own filtered task list (Vansh's set differs from Govind &
  /// Piyush's).
  ///
  /// Calling this more than once for the same date is safe — a `seeded` flag
  /// prevents double-seeding, and `setTaskStatus` (merge) always wins over
  /// whatever was seeded, so user progress is never overwritten.
  Future<void> initializeDay(String date, List<DailyTask> tasks) async {
    if (tasks.isEmpty) return;

    // ── Idempotency guard ────────────────────────────────────────────────
    final record = await _dayRecordDoc(date).get();
    if (record.exists) {
      final data = record.data() as Map<String, dynamic>;
      if (data['seeded'] == true) return; // already done
    }

    final batch = _db.batch();
    for (final member in Member.all) {
      final memberTasks = tasks.where((t) => t.appliesToMember(member.id));
      final taskMap = {for (final t in memberTasks) t.id: TaskStatus.pending.name};
      final ref = _completionDoc(member.id, date);
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, {
          'memberId': member.id,
          'date': date,
          'tasks': taskMap,
          'seededAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // ── Mark day as seeded ───────────────────────────────────────────────
    batch.set(_dayRecordDoc(date), {
      'date': date,
      'seeded': true,
      'seededAt': FieldValue.serverTimestamp(),
      'taskCount': tasks.length,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ── Admin unlocks ─────────────────────────────────────────────────────────

  DocumentReference _adminUnlockDoc(String date) =>
      _db.collection('admin_unlocks').doc(date);

  /// Returns true if an admin has unlocked [date] for editing.
  Future<bool> isAdminUnlocked(String date) async {
    final doc = await _adminUnlockDoc(date).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['unlocked'] as bool? ?? false;
  }

  Stream<bool> adminUnlockStream(String date) {
    return _adminUnlockDoc(date).snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      return data['unlocked'] as bool? ?? false;
    });
  }

  Future<void> setAdminUnlock(String date, {required bool unlock}) async {
    await _adminUnlockDoc(date).set({
      'date': date,
      'unlocked': unlock,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'vansh',
    }, SetOptions(merge: true));
  }

  // ── Completions ───────────────────────────────────────────────────────────

  DocumentReference _completionDoc(String memberId, String date) =>
      _db.collection('completions').doc('${memberId}_$date');

  Future<Map<String, TaskStatus>> fetchDayCompletions(
      String memberId, String date) async {
    final doc = await _completionDoc(memberId, date).get();
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>;
    final tasks = data['tasks'] as Map<String, dynamic>? ?? {};
    return tasks.map((k, v) => MapEntry(
          k,
          TaskStatus.values.firstWhere((s) => s.name == v,
              orElse: () => TaskStatus.pending),
        ));
  }

  Stream<Map<String, TaskStatus>> dayCompletionsStream(
      String memberId, String date) {
    return _completionDoc(memberId, date).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final tasks = data['tasks'] as Map<String, dynamic>? ?? {};
      return tasks.map((k, v) => MapEntry(
            k,
            TaskStatus.values.firstWhere((s) => s.name == v,
                orElse: () => TaskStatus.pending),
          ));
    });
  }

  Future<void> setTaskStatus(
      String memberId, String date, String taskId, TaskStatus status) async {
    await _completionDoc(memberId, date).set({
      'memberId': memberId,
      'date': date,
      'tasks': {taskId: status.name},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Members stats (today + any date) ─────────────────────────────────────

  Future<Map<String, Map<String, TaskStatus>>> fetchAllMembersDayCompletions(
      String date) async {
    final result = <String, Map<String, TaskStatus>>{};
    for (final member in Member.all) {
      result[member.id] = await fetchDayCompletions(member.id, date);
    }
    return result;
  }

  Stream<Map<String, Map<String, TaskStatus>>> allMembersDayStream(
      String date) {
    return _db
        .collection('completions')
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) {
      final result = <String, Map<String, TaskStatus>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String;
        final tasks = data['tasks'] as Map<String, dynamic>? ?? {};
        result[memberId] = tasks.map((k, v) => MapEntry(
              k,
              TaskStatus.values.firstWhere((s) => s.name == v,
                  orElse: () => TaskStatus.pending),
            ));
      }
      return result;
    });
  }

  // ── Calendar range ────────────────────────────────────────────────────────

  Future<Map<String, Map<String, TaskStatus>>> fetchMemberRange(
      String memberId, DateTime start, DateTime end) async {
    final result = <String, Map<String, TaskStatus>>{};
    final snap = await _db
        .collection('completions')
        .where('memberId', isEqualTo: memberId)
        .where('date', isGreaterThanOrEqualTo: dateKey(start))
        .where('date', isLessThanOrEqualTo: dateKey(end))
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = data['date'] as String;
      final tasks = data['tasks'] as Map<String, dynamic>? ?? {};
      result[date] = tasks.map((k, v) => MapEntry(
            k,
            TaskStatus.values.firstWhere((s) => s.name == v,
                orElse: () => TaskStatus.pending),
          ));
    }
    return result;
  }

  // ── Streaks (persisted in Firestore for fast reads) ───────────────────────

  Future<void> saveStreak(String memberId, StreakInfo info) async {
    await _db.collection('streaks').doc(memberId).set({
      'memberId': memberId,
      ...info.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, StreakInfo>> fetchAllStreaks() async {
    final snap = await _db.collection('streaks').get();
    final result = <String, StreakInfo>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      result[data['memberId'] as String] = StreakInfo.fromMap(data);
    }
    return result;
  }

  Stream<Map<String, StreakInfo>> streaksStream() {
    return _db.collection('streaks').snapshots().map((snap) {
      final result = <String, StreakInfo>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        result[data['memberId'] as String] = StreakInfo.fromMap(data);
      }
      return result;
    });
  }

  /// Recalculate streak stats from Firestore history (looks back up to 200
  /// days from the challenge start). Uses only the tasks that apply to
  /// [memberId] so Vansh's different task list doesn't skew his streak.
  Future<StreakInfo> calculateStreak(
      String memberId, List<DailyTask> allTasks) async {
    final memberTasks =
        allTasks.where((t) => t.appliesToMember(memberId)).toList();
    if (memberTasks.isEmpty) return const StreakInfo();

    final startDate = AppConstants.challengeStart;
    final today = DateTime.now();
    if (today.isBefore(startDate)) return const StreakInfo();

    int current = 0;
    int longest = 0;
    int missed = 0;
    int running = 0;
    bool stillCounting = true; // current streak counts back from today

    DateTime day = today;
    while (!day.isBefore(startDate)) {
      final dateStr = dateKey(day);
      final completions = await fetchDayCompletions(memberId, dateStr);
      final completedCount = memberTasks
          .where((t) => completions[t.id] == TaskStatus.completed)
          .length;
      final fullyDone = completedCount >= memberTasks.length;

      if (fullyDone) {
        running++;
        if (running > longest) longest = running;
      } else {
        // Today with pending tasks still counts toward the current streak
        // (it isn't "missed" until the day is over), but breaks the running
        // streak count for everything before it.
        if (dateStr != todayKey) missed++;
        if (stillCounting && dateStr == todayKey) {
          // don't break; just don't increment
        } else {
          if (stillCounting) {
            current = running;
            stillCounting = false;
          }
          running = 0;
        }
      }
      day = day.subtract(const Duration(days: 1));
    }
    if (stillCounting) current = running;
    if (longest < current) longest = current;

    return StreakInfo(current: current, longest: longest, missedDays: missed);
  }

  /// Recalculate streaks for all members and persist them.
  Future<void> recalculateAndSaveAllStreaks(List<DailyTask> tasks) async {
    for (final member in Member.all) {
      final info = await calculateStreak(member.id, tasks);
      await saveStreak(member.id, info);
    }
  }

  // ── Member profiles ───────────────────────────────────────────────────────

  DocumentReference _profileDoc(String memberId) =>
      _db.collection('profiles').doc(memberId);

  Future<void> saveProfile(MemberProfile memberProfile) async {
    await _profileDoc(memberProfile.memberId).set({
      ...memberProfile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Log the weight so admins can see a history over time.
    await _db.collection('weight_logs').add({
      'memberId': memberProfile.memberId,
      'weightKg': memberProfile.weightKg,
      'date': DateTime.now().toIso8601String(),
      'loggedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> fetchProfileRaw(String memberId) async {
    final doc = await _profileDoc(memberId).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  Stream<Map<String, dynamic>?> profileStream(String memberId) {
    return _profileDoc(memberId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>;
    });
  }

  Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    final result = <Map<String, dynamic>>[];
    for (final member in Member.all) {
      final data = await fetchProfileRaw(member.id);
      if (data != null) result.add(data);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchWeightHistory(String memberId) async {
    final snap = await _db
        .collection('weight_logs')
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .limit(60)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ── Weekly progress photos ────────────────────────────────────────────────

  DocumentReference _progressDoc(String memberId, int weekNumber) =>
      _db.collection('progress_photos').doc('${memberId}_week$weekNumber');

  Future<String> uploadProgressPhoto({
    required String memberId,
    required int weekNumber,
    required ProgressPhotoType type,
    required File file,
  }) async {
    final ref = _storage
        .ref()
        .child('progress_photos/$memberId/week$weekNumber/${type.name}.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _progressDoc(memberId, weekNumber).set({
      'memberId': memberId,
      'weekNumber': weekNumber,
      type.field: url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Future<WeeklyProgressPhotos?> fetchProgressWeek(
      String memberId, int weekNumber) async {
    final doc = await _progressDoc(memberId, weekNumber).get();
    if (!doc.exists) return null;
    return WeeklyProgressPhotos.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<List<WeeklyProgressPhotos>> fetchAllProgressForMember(
      String memberId) async {
    final snap = await _db
        .collection('progress_photos')
        .where('memberId', isEqualTo: memberId)
        .get();
    final list = snap.docs
        .map((d) => WeeklyProgressPhotos.fromMap(d.data()))
        .toList();
    list.sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
    return list;
  }

  /// Admin-only: fetch every member's progress photos, grouped by memberId.
  Future<Map<String, List<WeeklyProgressPhotos>>> fetchAllProgressPhotos() async {
    final result = <String, List<WeeklyProgressPhotos>>{};
    for (final member in Member.all) {
      result[member.id] = await fetchAllProgressForMember(member.id);
    }
    return result;
  }
}
