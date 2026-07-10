import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  FirebaseService get firebase => _firebase;
  final NotificationService _notifications = NotificationService();

  Member? _currentMember;
  List<DailyTask> _tasks = [];
  Map<String, TaskStatus> _todayCompletions = {};
  Map<String, Map<String, TaskStatus>> _allMembersToday = {};
  Map<String, Map<String, TaskStatus>> _calendarData = {};
  Map<String, int> _streaks = {};
  bool _loading = true;

  Member? get currentMember => _currentMember;
  List<DailyTask> get tasks => _tasks;
  Map<String, TaskStatus> get todayCompletions => _todayCompletions;
  Map<String, Map<String, TaskStatus>> get allMembersToday => _allMembersToday;
  Map<String, Map<String, TaskStatus>> get calendarData => _calendarData;
  Map<String, int> get streaks => _streaks;
  bool get loading => _loading;
  bool get isAdmin => _currentMember?.isAdmin ?? false;

  String get todayKey =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('member_id');
    if (savedId != null) {
      _currentMember = Member.fromId(savedId);
    }

    await _notifications.init();

    if (_currentMember != null) {
      await _loadAll();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> selectMember(Member member) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('member_id', member.id);
    _currentMember = member;
    await _loadAll();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadTasks(),
      _loadTodayCompletions(),
      _loadAllMembersToday(),
    ]);
    _loadStreaks();
    notifyListeners();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> _loadTasks() async {
    _tasks = await _firebase.fetchTasks();
    await _notifications.scheduleTaskReminders(_tasks);
  }

  void listenTasks() {
    _firebase.tasksStream().listen((tasks) {
      _tasks = tasks;
      _notifications.scheduleTaskReminders(tasks);
      notifyListeners();
    });
  }

  Future<void> addTask(DailyTask task) async {
    await _firebase.saveTask(task, _tasks.length);
    _tasks = await _firebase.fetchTasks();
    await _notifications.scheduleTaskReminders(_tasks);
    notifyListeners();
  }

  Future<void> updateTask(DailyTask task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    await _firebase.saveTask(task, idx >= 0 ? idx : _tasks.length);
    _tasks = await _firebase.fetchTasks();
    await _notifications.scheduleTaskReminders(_tasks);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _firebase.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  // ── Completions ───────────────────────────────────────────────────────────

  Future<void> _loadTodayCompletions() async {
    if (_currentMember == null) return;
    _todayCompletions =
        await _firebase.fetchDayCompletions(_currentMember!.id, todayKey);
  }

  void listenTodayCompletions() {
    if (_currentMember == null) return;
    _firebase
        .dayCompletionsStream(_currentMember!.id, todayKey)
        .listen((completions) {
      _todayCompletions = completions;
      notifyListeners();
    });
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    if (_currentMember == null) return;
    await _firebase.setTaskStatus(
        _currentMember!.id, todayKey, taskId, status);
    _todayCompletions[taskId] = status;
    notifyListeners();
  }

  // ── All members ───────────────────────────────────────────────────────────

  Future<void> _loadAllMembersToday() async {
    _allMembersToday =
        await _firebase.fetchAllMembersDayCompletions(todayKey);
  }

  void listenAllMembersToday() {
    _firebase.allMembersDayStream(todayKey).listen((data) {
      _allMembersToday = data;
      notifyListeners();
    });
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Future<void> loadCalendarRange(DateTime start, DateTime end) async {
    if (_currentMember == null) return;
    _calendarData =
        await _firebase.fetchMemberRange(_currentMember!.id, start, end);
    notifyListeners();
  }

  // ── Streaks ───────────────────────────────────────────────────────────────

  Future<void> _loadStreaks() async {
    for (final member in Member.all) {
      _streaks[member.id] =
          await _firebase.calculateStreak(member.id, _tasks);
    }
    notifyListeners();
  }

  // ── Stats helpers ─────────────────────────────────────────────────────────

  double completionPercent(Map<String, TaskStatus> completions) {
    if (_tasks.isEmpty) return 0;
    final completed =
        completions.values.where((s) => s == TaskStatus.completed).length;
    return completed / _tasks.length;
  }

  int completedCount(Map<String, TaskStatus> completions) =>
      completions.values.where((s) => s == TaskStatus.completed).length;

  int remainingCount(Map<String, TaskStatus> completions) {
    final done =
        completions.values.where((s) => s != TaskStatus.pending).length;
    return (_tasks.length - done).clamp(0, _tasks.length);
  }

  TaskStatus statusOf(String taskId) =>
      _todayCompletions[taskId] ?? TaskStatus.pending;

  // ── Leaderboard ───────────────────────────────────────────────────────────

  List<Member> get leaderboardByCompletion {
    final members = List<Member>.from(Member.all);
    members.sort((a, b) {
      final aP =
          completionPercent(_allMembersToday[a.id] ?? {});
      final bP =
          completionPercent(_allMembersToday[b.id] ?? {});
      return bP.compareTo(aP);
    });
    return members;
  }

  List<Member> get leaderboardByStreak {
    final members = List<Member>.from(Member.all);
    members.sort((a, b) {
      final aS = _streaks[a.id] ?? 0;
      final bS = _streaks[b.id] ?? 0;
      return bS.compareTo(aS);
    });
    return members;
  }
}
