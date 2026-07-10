import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
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

  // ── History / locking ─────────────────────────────────────────────────────
  String? _historyDate;
  Map<String, Map<String, TaskStatus>> _historyData = {};
  bool _historyLoading = false;
  bool _historyDateAdminUnlocked = false;

  // ── Day-change detection ──────────────────────────────────────────────────
  String _lastKnownDate = '';

  // ── Getters ───────────────────────────────────────────────────────────────

  Member? get currentMember => _currentMember;
  List<DailyTask> get tasks => _tasks;
  Map<String, TaskStatus> get todayCompletions => _todayCompletions;
  Map<String, Map<String, TaskStatus>> get allMembersToday => _allMembersToday;
  Map<String, Map<String, TaskStatus>> get calendarData => _calendarData;
  Map<String, int> get streaks => _streaks;
  bool get loading => _loading;
  bool get isAdmin => _currentMember?.isAdmin ?? false;

  String? get historyDate => _historyDate;
  Map<String, Map<String, TaskStatus>> get historyData => _historyData;
  bool get historyLoading => _historyLoading;
  bool get historyDateAdminUnlocked => _historyDateAdminUnlocked;

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// True when a date is before today.
  bool isDateLocked(String date) => FirebaseService.isDateLocked(date);

  /// Can the current user edit tasks for [date]?
  /// - Today: always yes
  /// - Past + admin-unlocked + user is admin: yes
  /// - Past otherwise: no
  bool canEditDate(String date) {
    if (!isDateLocked(date)) return true; // today
    return isAdmin && _historyDateAdminUnlocked;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    WidgetsBinding.instance.addObserver(this);
    _lastKnownDate = todayKey;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDayChange();
    }
  }

  Future<void> _checkDayChange() async {
    final currentDate = todayKey;
    if (currentDate != _lastKnownDate) {
      _lastKnownDate = currentDate;
      await _refreshForNewDay(currentDate);
    }
  }

  /// Triggered automatically when the calendar flips to a new day.
  Future<void> _refreshForNewDay(String date) async {
    // Seed the fresh daily checklist using the admin-defined task list
    await _firebase.initializeDay(date, _tasks);
    // Recalculate streaks
    await _firebase.recalculateAndSaveAllStreaks(_tasks);
    // Reload app state fresh
    _todayCompletions = {};
    _allMembersToday = {};
    await Future.wait([
      _loadTodayCompletions(),
      _loadAllMembersToday(),
      _loadStreaks(),
    ]);
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> selectMember(Member member) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('member_id', member.id);
    _currentMember = member;
    await _loadAll();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    // Tasks must be loaded before we can seed today's checklist.
    await _loadTasks();
    await Future.wait([
      _loadTodayCompletions(),
      _loadAllMembersToday(),
      _loadStreaks(),
    ]);
    // Seed today's fresh checklist for all members (idempotent — skips if
    // already seeded; never overwrites completions the user has already made).
    _firebase.initializeDay(todayKey, _tasks);
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

  // ── Today completions ─────────────────────────────────────────────────────

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
    // Recalculate streak live
    final streak =
        await _firebase.calculateStreak(_currentMember!.id, _tasks);
    await _firebase.saveStreak(_currentMember!.id, streak);
    _streaks[_currentMember!.id] = streak;
    notifyListeners();
  }

  // ── All members (today) ───────────────────────────────────────────────────

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
    // Try fast path: persisted streaks
    final persisted = await _firebase.fetchAllStreaks();
    if (persisted.isNotEmpty) {
      _streaks = persisted;
      notifyListeners();
      return;
    }
    // Fallback: recalculate and persist
    for (final member in Member.all) {
      final s = await _firebase.calculateStreak(member.id, _tasks);
      _streaks[member.id] = s;
      await _firebase.saveStreak(member.id, s);
    }
    notifyListeners();
  }

  void listenStreaks() {
    _firebase.streaksStream().listen((data) {
      _streaks = data;
      notifyListeners();
    });
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<void> loadHistoryDate(String date) async {
    _historyDate = date;
    _historyLoading = true;
    _historyData = {};
    notifyListeners();

    final results = await Future.wait([
      _firebase.fetchAllMembersDayCompletions(date),
      _firebase.isAdminUnlocked(date),
    ]);

    _historyData = results[0] as Map<String, Map<String, TaskStatus>>;
    _historyDateAdminUnlocked = results[1] as bool;
    _historyLoading = false;
    notifyListeners();
  }

  Future<void> toggleHistoryAdminUnlock(String date) async {
    if (!isAdmin) return;
    final newState = !_historyDateAdminUnlocked;
    await _firebase.setAdminUnlock(date, unlock: newState);
    _historyDateAdminUnlocked = newState;
    notifyListeners();
  }

  /// Admin editing a past day's task for any member.
  Future<void> setHistoryTaskStatus(
      String memberId, String date, String taskId, TaskStatus status) async {
    if (!isAdmin) return;
    await _firebase.setTaskStatus(memberId, date, taskId, status);
    _historyData[memberId] ??= {};
    _historyData[memberId]![taskId] = status;
    // Recalculate streak for affected member
    final streak = await _firebase.calculateStreak(memberId, _tasks);
    await _firebase.saveStreak(memberId, streak);
    _streaks[memberId] = streak;
    notifyListeners();
  }

  void clearHistory() {
    _historyDate = null;
    _historyData = {};
    _historyDateAdminUnlocked = false;
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
      final aP = completionPercent(_allMembersToday[a.id] ?? {});
      final bP = completionPercent(_allMembersToday[b.id] ?? {});
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
