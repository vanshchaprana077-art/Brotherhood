class DailyTask {
  final String id;
  final String title;
  final String icon;
  final String? description;    // admin-visible note about the task
  final String? targetValue;    // e.g. "5L", "20 mins", "10 pages"
  final String? category;       // e.g. "Health", "Discipline", "Fitness"
  final String? notificationTime; // "HH:mm" format, null = no notification
  final bool isDefault;

  /// Which members this task applies to. Empty or null list means it
  /// applies to everyone. Used so Vansh can have a different task set
  /// than Govind & Piyush.
  final List<String>? appliesTo;

  const DailyTask({
    required this.id,
    required this.title,
    required this.icon,
    this.description,
    this.targetValue,
    this.category,
    this.notificationTime,
    this.isDefault = false,
    this.appliesTo,
  });

  bool appliesToMember(String memberId) =>
      appliesTo == null || appliesTo!.isEmpty || appliesTo!.contains(memberId);

  /// Canonical task set. Common tasks apply to everyone; a handful are
  /// scoped to specific members (Water target differs, and Vansh carries
  /// extra tasks that Govind & Piyush do not have).
  static List<DailyTask> get defaults => [
        // ── Common tasks (everyone) ──────────────────────────────────────
        const DailyTask(
          id: 'wake_up_early',
          title: 'Wake Up Early',
          icon: '⏰',
          category: 'Discipline',
          notificationTime: '06:00',
          isDefault: true,
        ),
        const DailyTask(
          id: 'gym_workout',
          title: 'Gym Workout',
          icon: '🏋️',
          category: 'Fitness',
          notificationTime: '17:00',
          isDefault: true,
        ),
        const DailyTask(
          id: 'screen_time',
          title: 'Screen Time Under 5 Hrs',
          icon: '📱',
          category: 'Discipline',
          targetValue: '<5 hrs',
          isDefault: true,
        ),
        const DailyTask(
          id: 'social_media',
          title: 'Social Media Under 3 Hrs',
          icon: '📲',
          category: 'Discipline',
          targetValue: '<3 hrs',
          isDefault: true,
        ),
        const DailyTask(
          id: 'avoid_phone',
          title: 'Avoid Phone After 11 PM',
          icon: '🌙',
          category: 'Discipline',
          notificationTime: '23:00',
          isDefault: true,
        ),
        const DailyTask(
          id: 'sleep_on_time',
          title: 'Sleep Before 11 PM',
          icon: '😴',
          category: 'Health',
          notificationTime: '22:30',
          isDefault: true,
        ),
        const DailyTask(
          id: 'meditation',
          title: 'Meditation',
          icon: '🧘',
          category: 'Health',
          notificationTime: '06:30',
          isDefault: true,
        ),
        const DailyTask(
          id: 'journaling',
          title: 'Journaling',
          icon: '📓',
          category: 'Discipline',
          notificationTime: '21:30',
          isDefault: true,
        ),
        const DailyTask(
          id: 'read_book',
          title: 'Read Book',
          icon: '📖',
          category: 'Growth',
          isDefault: true,
        ),
        const DailyTask(
          id: 'cold_shower',
          title: 'Cold Shower',
          icon: '🚿',
          category: 'Health',
          isDefault: true,
        ),

        // ── Water (target differs per member) ────────────────────────────
        const DailyTask(
          id: 'water_gp',
          title: 'Drink Water (4L)',
          icon: '💧',
          category: 'Health',
          targetValue: '4L',
          notificationTime: '08:00',
          isDefault: true,
          appliesTo: ['govind', 'piyush'],
        ),
        const DailyTask(
          id: 'water_vansh',
          title: 'Drink Water (5L)',
          icon: '💧',
          category: 'Health',
          targetValue: '5L',
          notificationTime: '08:00',
          isDefault: true,
          appliesTo: ['vansh'],
        ),

        // ── Vansh-only tasks ──────────────────────────────────────────────
        const DailyTask(
          id: 'adequate_meals',
          title: '3 Adequate Meals',
          icon: '🍽️',
          category: 'Health',
          targetValue: '3 meals',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'dry_fruits',
          title: 'Eat Dry Fruits',
          icon: '🥜',
          category: 'Health',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'business',
          title: 'Business',
          icon: '💼',
          category: 'Growth',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'looksmaxing',
          title: 'Looksmaxing',
          icon: '✨',
          category: 'Health',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'pray_calm_kind',
          title: 'Pray, Be Calm, Be Kind',
          icon: '🙏',
          category: 'Discipline',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'study',
          title: 'Study',
          icon: '📚',
          category: 'Growth',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'coding',
          title: 'Coding',
          icon: '💻',
          category: 'Growth',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'shoulder_workout',
          title: 'Shoulder Workout',
          icon: '💪',
          category: 'Fitness',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
        const DailyTask(
          id: 'learn_french',
          title: 'Learn French',
          icon: '🇫🇷',
          category: 'Growth',
          isDefault: true,
          appliesTo: ['vansh'],
        ),
      ];

  DailyTask copyWith({
    String? id,
    String? title,
    String? icon,
    String? description,
    String? targetValue,
    String? category,
    String? notificationTime,
    bool? isDefault,
    List<String>? appliesTo,
    bool clearNotificationTime = false,
    bool clearAppliesTo = false,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      category: category ?? this.category,
      notificationTime:
          clearNotificationTime ? null : (notificationTime ?? this.notificationTime),
      isDefault: isDefault ?? this.isDefault,
      appliesTo: clearAppliesTo ? null : (appliesTo ?? this.appliesTo),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'description': description,
        'targetValue': targetValue,
        'category': category,
        'notificationTime': notificationTime,
        'isDefault': isDefault,
        'appliesTo': appliesTo,
      };

  factory DailyTask.fromMap(Map<String, dynamic> map) => DailyTask(
        id: map['id'] as String,
        title: map['title'] as String,
        icon: map['icon'] as String? ?? '✅',
        description: map['description'] as String?,
        targetValue: map['targetValue'] as String?,
        category: map['category'] as String?,
        notificationTime: map['notificationTime'] as String?,
        isDefault: map['isDefault'] as bool? ?? false,
        appliesTo: (map['appliesTo'] as List?)?.map((e) => e.toString()).toList(),
      );

  @override
  bool operator ==(Object other) => other is DailyTask && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum TaskStatus { completed, missed, pending }

class TaskCompletion {
  final String taskId;
  final String memberId;
  final String date; // yyyy-MM-dd
  final TaskStatus status;

  const TaskCompletion({
    required this.taskId,
    required this.memberId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'memberId': memberId,
        'date': date,
        'status': status.name,
      };

  factory TaskCompletion.fromMap(Map<String, dynamic> map) => TaskCompletion(
        taskId: map['taskId'] as String,
        memberId: map['memberId'] as String,
        date: map['date'] as String,
        status: TaskStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => TaskStatus.pending,
        ),
      );
}
