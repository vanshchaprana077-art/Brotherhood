import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../models/profile.dart';
import '../models/streak_info.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

/// Wraps a future so it can never hang the UI forever. If it doesn't
/// resolve within [duration] (default 5s) or it throws, [fallback] is
/// returned instead.
Future<T> withTimeout<T>(
  Future<T> future,
  T fallback, {
  Duration duration = const Duration(seconds: 5),
}) async {
  try {
    return await future.timeout(duration, onTimeout: () => fallback);
  } catch (_) {
    return fallback;
  }
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseService _firebase = FirebaseService();
  FirebaseService get firebase => _firebase;
  final NotificationService _notifications = NotificationService();

  Member? _currentMember;
  List<DailyTask> _tasks = [];
  Map<String, TaskStatus> _todayCompletions = {};
  Map<String, Map<String, TaskStatus>> _allMembersToday = {};
  Map<String, Map<String, TaskStatus>> _calendarData = {};
  Map<String, StreakInfo> _streaks = {};
  MemberProfile? _profile;
  bool _profileChecked = false;
  bool _loading = true;
  bool _adminPanelUnlocked = false;

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
  Map<String, StreakInfo> get streaks => _streaks;
  MemberProfile? get profile => _profile;
  bool get loading => _loading;
  bool get isAdmin => _currentMember?.isAdmin ?? false;
  bool get adminPanelUnlocked => _adminPanelUnlocked;

  /// True once we've selected a member but haven't saved a profile yet —
  /// triggers the first-time profile setup screen.
  bool get needsProfileSetup =>
      _currentMember != null && _profileChecked && _profile == null;

  String? get historyDate => _historyDate;
  Map<String, Map<String, TaskStatus>> get historyData => _historyData;
  bool get historyLoading => _historyLoading;
  bool get historyDateAdminUnlocked => _historyDateAdminUnlocked;

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool isDateLocked(String date) => FirebaseService.isDateLocked(date);

  bool canEditDate(String date) {
    if (!isDateLocked(date)) return true;
    return isAdmin && _historyDateAdminUnlocked;
  }

  // ── Challenge timing ──────────────────────────────────────────────────────

  int get currentDayNumber {
    final now = DateTime.now();
    if (now.isBefore(AppConstants.challengeStart)) return 0;
    return now.difference(AppConstants.challengeStart).inDays + 1;
  }

  int get daysRemaining {
    final elapsed = currentDayNumber;
    if (elapsed <= 0) return AppConstants.challengeDurationDays;
    return (AppConstants.challengeDurationDays - elapsed).clamp(0, AppConstants.challengeDurationDays);
  }

  bool get challengeStarted => currentDayNumber > 0;

  int get currentWeekNumber => FirebaseService.weekNumberFor(DateTime.now());

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

    await withTimeout(_notifications.init(), null, duration: const Duration(seconds: 3));

    if (_currentMember != null) {
      await withTimeout(_loadAll(), null, duration: const Duration(seconds: 5));
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

  Future<void> _refreshForNewDay(String date) async {
    await withTimeout(_firebase.initializeDay(date, _tasks), null);
    await withTimeout(_firebase.recalculateAndSaveAllStreaks(_tasks), null);
    _todayCompletions = {};
    _allMembersToday = {};
    await withTimeout(
      Future.wait([
        _loadTodayCompletions(),
        _loadAllMembersToday(),
        _loadStreaks(),
      ]),
      null,
    );
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
    _profileChecked = false;
    _profile = null;
    await withTimeout(_loadAll(), null, duration: const Duration(seconds: 5));
    notifyListeners();
  }

  Future<void> _loadAll() async {
    await withTimeout(_loadTasks(), null);
    await withTimeout(
      Future.wait([
        _loadTodayCompletions(),
        _loadAllMembersToday(),
        _loadStreaks(),
        _loadProfile(),
      ]),
      null,
    );
    // ignore: unawaited_futures
    withTimeout(_firebase.initializeDay(todayKey, _tasks), null);
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentMember == null) return;
    await withTimeout(_loadAll(), null, duration: const Duration(seconds: 5));
    notifyListeners();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> _loadTasks() async {
    _tasks = await withTimeout(_firebase.fetchTasks(), <DailyTask>[]);
    if (_tasks.isEmpty) _tasks = DailyTask.defaults;
    if (_currentMember != null) {
      await withTimeout(
        _notifications.scheduleTaskReminders(tasksForMember(_currentMember!.id)),
        null,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void listenTasks() {
    _firebase.tasksStream().listen((tasks) {
      _tasks = tasks;
      if (_currentMember != null) {
        _notifications.scheduleTaskReminders(tasksForMember(_currentMember!.id));
      }
      notifyListeners();
    });
  }

  List<DailyTask> tasksForMember(String memberId) =>
      _tasks.where((t) => t.appliesToMember(memberId)).toList();

  List<DailyTask> get tasksForCurrentMember =>
      _currentMember == null ? [] : tasksForMember(_currentMember!.id);

  Future<void> addTask(DailyTask task) async {
    try {
      await _firebase.saveTask(task, _tasks.length);
      _tasks = await _firebase.fetchTasks();
    } catch (_) {
      // Firebase not configured; update locally
      _tasks = [..._tasks, task];
    }
    if (_currentMember != null) {
      await withTimeout(
        _notifications.scheduleTaskReminders(tasksForMember(_currentMember!.id)),
        null,
        duration: const Duration(seconds: 3),
      );
    }
    notifyListeners();
  }

  Future<void> updateTask(DailyTask task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    try {
      await _firebase.saveTask(task, idx >= 0 ? idx : _tasks.length);
      _tasks = await _firebase.fetchTasks();
    } catch (_) {
      // Firebase not configured; update locally
      if (idx >= 0) {
        final updated = List<DailyTask>.from(_tasks);
        updated[idx] = task;
        _tasks = updated;
      }
    }
    if (_currentMember != null) {
      await withTimeout(
        _notifications.scheduleTaskReminders(tasksForMember(_currentMember!.id)),
        null,
        duration: const Duration(seconds: 3),
      );
    }
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firebase.deleteTask(taskId);
    } catch (_) {}
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  // ── Today completions ─────────────────────────────────────────────────────

  Future<void> _loadTodayCompletions() async {
    if (_currentMember == null) return;
    _todayCompletions = await withTimeout(
      _firebase.fetchDayCompletions(_currentMember!.id, todayKey),
      <String, TaskStatus>{},
    );
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

  /// Updates a task status immediately in local state, then syncs to Firebase
  /// in the background. The UI reacts instantly; Firebase failure is silent.
  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    if (_currentMember == null) return;
    // Immediate optimistic update — UI reacts instantly
    _todayCompletions[taskId] = status;
    notifyListeners();
    // Background Firebase sync (fire-and-forget)
    try {
      await _firebase.setTaskStatus(_currentMember!.id, todayKey, taskId, status);
      final info = await _firebase.calculateStreak(_currentMember!.id, _tasks);
      await _firebase.saveStreak(_currentMember!.id, info);
      _streaks[_currentMember!.id] = info;
      notifyListeners();
    } catch (_) {
      // Firebase not configured or unreachable; local state already reflects change
    }
  }

  // ── All members (today) ───────────────────────────────────────────────────

  Future<void> _loadAllMembersToday() async {
    _allMembersToday = await withTimeout(
      _firebase.fetchAllMembersDayCompletions(todayKey),
      <String, Map<String, TaskStatus>>{},
    );
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
    final persisted = await withTimeout(
      _firebase.fetchAllStreaks(),
      <String, StreakInfo>{},
    );
    if (persisted.isNotEmpty) {
      _streaks = persisted;
      notifyListeners();
      return;
    }
    for (final member in Member.all) {
      final info = await withTimeout(
        _firebase.calculateStreak(member.id, _tasks),
        const StreakInfo(),
      );
      _streaks[member.id] = info;
      // ignore: unawaited_futures
      _firebase.saveStreak(member.id, info);
    }
    notifyListeners();
  }

  void listenStreaks() {
    _firebase.streaksStream().listen((data) {
      _streaks = data;
      notifyListeners();
    });
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    if (_currentMember == null) return;
    final raw = await withTimeout(
      _firebase.fetchProfileRaw(_currentMember!.id),
      null,
    );
    _profile = raw == null ? null : MemberProfile.fromMap(raw);
    _profileChecked = true;
  }

  void listenProfile() {
    if (_currentMember == null) return;
    _firebase.profileStream(_currentMember!.id).listen((raw) {
      _profile = raw == null ? null : MemberProfile.fromMap(raw);
      _profileChecked = true;
      notifyListeners();
    });
  }

  /// Saves profile to Firebase, then updates local state. Navigates away
  /// from ProfileSetupScreen even if Firebase is unreachable (e.g. placeholder
  /// credentials) by always setting _profile and notifying.
  Future<void> saveProfile(MemberProfile profile) async {
    try {
      await _firebase.saveProfile(profile);
    } catch (_) {
      // Firebase may not be configured yet; save in local state and continue
    }
    _profile = profile;
    _profileChecked = true;
    notifyListeners();
  }

  /// Updates profile details (height, weight, age, etc.) and re-saves.
  Future<void> updateProfile(MemberProfile profile) => saveProfile(profile);

  // ── Admin panel access ────────────────────────────────────────────────────

  bool tryUnlockAdminPanel(String password) {
    final ok = password == AppConstants.adminPassword;
    if (ok) {
      _adminPanelUnlocked = true;
      notifyListeners();
    }
    return ok;
  }

  void lockAdminPanel() {
    _adminPanelUnlocked = false;
    notifyListeners();
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
    if (!isAdmin && !_adminPanelUnlocked) return;
    final newState = !_historyDateAdminUnlocked;
    await _firebase.setAdminUnlock(date, unlock: newState);
    _historyDateAdminUnlocked = newState;
    notifyListeners();
  }

  Future<void> setHistoryTaskStatus(
      String memberId, String date, String taskId, TaskStatus status) async {
    if (!isAdmin && !_adminPanelUnlocked) return;
    await _firebase.setTaskStatus(memberId, date, taskId, status);
    _historyData[memberId] ??= {};
    _historyData[memberId]![taskId] = status;
    final info = await _firebase.calculateStreak(memberId, _tasks);
    await _firebase.saveStreak(memberId, info);
    _streaks[memberId] = info;
    notifyListeners();
  }

  void clearHistory() {
    _historyDate = null;
    _historyData = {};
    _historyDateAdminUnlocked = false;
    notifyListeners();
  }

  // ── Stats helpers ─────────────────────────────────────────────────────────

  double completionPercent(Map<String, TaskStatus> completions, {String? memberId}) {
    final relevant = tasksForMember(memberId ?? _currentMember?.id ?? '');
    if (relevant.isEmpty) return 0;
    final completed =
        relevant.where((t) => completions[t.id] == TaskStatus.completed).length;
    return completed / relevant.length;
  }

  int completedCount(Map<String, TaskStatus> completions, {String? memberId}) {
    final relevant = tasksForMember(memberId ?? _currentMember?.id ?? '');
    return relevant.where((t) => completions[t.id] == TaskStatus.completed).length;
  }

  int taskCountFor(String memberId) => tasksForMember(memberId).length;

  int remainingCount(Map<String, TaskStatus> completions, {String? memberId}) {
    final relevant = tasksForMember(memberId ?? _currentMember?.id ?? '');
    final done = relevant
        .where((t) => (completions[t.id] ?? TaskStatus.pending) != TaskStatus.pending)
        .length;
    return (relevant.length - done).clamp(0, relevant.length);
  }

  TaskStatus statusOf(String taskId) =>
      _todayCompletions[taskId] ?? TaskStatus.pending;

  int get todaysScore => completedCount(_todayCompletions);

  double get todaysPercent => completionPercent(_todayCompletions);

  int get dailyRank {
    if (_currentMember == null) return 0;
    final ranked = leaderboardByCompletion;
    final idx = ranked.indexWhere((m) => m.id == _currentMember!.id);
    return idx == -1 ? 0 : idx + 1;
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  List<Member> get leaderboardByCompletion {
    final members = List<Member>.from(Member.all);
    members.sort((a, b) {
      final aP = completionPercent(_allMembersToday[a.id] ?? {}, memberId: a.id);
      final bP = completionPercent(_allMembersToday[b.id] ?? {}, memberId: b.id);
      final cmp = bP.compareTo(aP);
      if (cmp != 0) return cmp;
      final aS = _streaks[a.id]?.current ?? 0;
      final bS = _streaks[b.id]?.current ?? 0;
      return bS.compareTo(aS);
    });
    return members;
  }

  List<Member> get leaderboardByStreak {
    final members = List<Member>.from(Member.all);
    members.sort((a, b) {
      final aS = _streaks[a.id]?.current ?? 0;
      final bS = _streaks[b.id]?.current ?? 0;
      return bS.compareTo(aS);
    });
    return members;
  }
}
