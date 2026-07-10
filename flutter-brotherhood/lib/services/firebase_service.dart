import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/member.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String get todayKey => dateKey(DateTime.now());

  /// A date is locked when it is before today.
  static bool isDateLocked(String date) {
    final today = todayKey;
    return date.compareTo(today) < 0;
  }

  // ── Tasks config ──────────────────────────────────────────────────────────

  CollectionReference get _tasksCol => _db.collection('tasks_config');

  Future<List<DailyTask>> fetchTasks() async {
    final snap = await _tasksCol.orderBy('order').get();
    if (snap.docs.isEmpty) {
      await seedDefaultTasks();
      return DailyTask.defaults;
    }
    return snap.docs
        .map((d) => DailyTask.fromMap(d.data() as Map<String, dynamic>))
        .toList();
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

  /// Called at midnight to stamp the new day into Firestore.
  Future<void> initializeDay(String date) async {
    await _dayRecordDoc(date).set({
      'date': date,
      'initializedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<void> saveStreak(String memberId, int streak) async {
    await _db.collection('streaks').doc(memberId).set({
      'memberId': memberId,
      'streak': streak,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, int>> fetchAllStreaks() async {
    final snap = await _db.collection('streaks').get();
    final result = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      result[data['memberId'] as String] = data['streak'] as int? ?? 0;
    }
    return result;
  }

  Stream<Map<String, int>> streaksStream() {
    return _db.collection('streaks').snapshots().map((snap) {
      final result = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        result[data['memberId'] as String] = data['streak'] as int? ?? 0;
      }
      return result;
    });
  }

  /// Recalculate streak from Firestore history (looks back up to 90 days).
  Future<int> calculateStreak(String memberId, List<DailyTask> tasks) async {
    if (tasks.isEmpty) return 0;
    int streak = 0;
    DateTime day = DateTime.now();
    final startDate = DateTime(2026, 7, 12);
    // Skip today if not yet complete — streak counts fully-done days
    // (start checking from today so partial days still count)
    for (int i = 0; i < 90; i++) {
      if (day.isBefore(startDate)) break;
      final dateStr = dateKey(day);
      final completions = await fetchDayCompletions(memberId, dateStr);
      final completed =
          completions.values.where((s) => s == TaskStatus.completed).length;
      if (completed < tasks.length) {
        // today with pending tasks still counts as active — skip only if it's
        // a past day with < 100%
        if (dateStr != todayKey) break;
      } else {
        streak++;
      }
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Recalculate streaks for all members and persist them.
  Future<void> recalculateAndSaveAllStreaks(List<DailyTask> tasks) async {
    for (final member in Member.all) {
      final streak = await calculateStreak(member.id, tasks);
      await saveStreak(member.id, streak);
    }
  }
}
