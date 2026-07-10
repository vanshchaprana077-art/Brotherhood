class DailyTask {
  final String id;
  final String title;
  final String icon;
  final String? notificationTime; // "HH:mm" format, null = no notification
  final bool isDefault;

  const DailyTask({
    required this.id,
    required this.title,
    required this.icon,
    this.notificationTime,
    this.isDefault = false,
  });

  static List<DailyTask> get defaults => [
        const DailyTask(
          id: 'drink_water',
          title: 'Drink Water',
          icon: '💧',
          notificationTime: '08:00',
          isDefault: true,
        ),
        const DailyTask(
          id: 'workout',
          title: 'Workout',
          icon: '🏋️',
          notificationTime: '07:00',
          isDefault: true,
        ),
        const DailyTask(
          id: 'study',
          title: 'Study',
          icon: '📚',
          notificationTime: '10:00',
          isDefault: true,
        ),
        const DailyTask(
          id: 'read_book',
          title: 'Read Book',
          icon: '📖',
          notificationTime: null,
          isDefault: true,
        ),
        const DailyTask(
          id: 'sleep_before_11',
          title: 'Sleep Before 11 PM',
          icon: '😴',
          notificationTime: '22:30',
          isDefault: true,
        ),
        const DailyTask(
          id: 'no_smoking',
          title: 'No Smoking',
          icon: '🚭',
          notificationTime: null,
          isDefault: true,
        ),
      ];

  DailyTask copyWith({
    String? id,
    String? title,
    String? icon,
    String? notificationTime,
    bool? isDefault,
    bool clearNotificationTime = false,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      notificationTime:
          clearNotificationTime ? null : (notificationTime ?? this.notificationTime),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'notificationTime': notificationTime,
        'isDefault': isDefault,
      };

  factory DailyTask.fromMap(Map<String, dynamic> map) => DailyTask(
        id: map['id'] as String,
        title: map['title'] as String,
        icon: map['icon'] as String? ?? '✅',
        notificationTime: map['notificationTime'] as String?,
        isDefault: map['isDefault'] as bool? ?? false,
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
