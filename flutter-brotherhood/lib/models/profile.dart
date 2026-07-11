class MemberProfile {
  final String memberId;
  final double heightCm;
  final double weightKg;
  final String goal;
  final double? bodyFatPercent; // optional
  final int age;
  final DateTime? updatedAt;

  const MemberProfile({
    required this.memberId,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    this.bodyFatPercent,
    required this.age,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal,
        'bodyFatPercent': bodyFatPercent,
        'age': age,
      };

  factory MemberProfile.fromMap(Map<String, dynamic> map) => MemberProfile(
        memberId: map['memberId'] as String,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
        goal: map['goal'] as String? ?? '',
        bodyFatPercent: (map['bodyFatPercent'] as num?)?.toDouble(),
        age: (map['age'] as num?)?.toInt() ?? 0,
      );
}

/// A single weight entry, logged automatically whenever a profile is saved
/// with a new weight so the admin can see a weight history over time.
class WeightLog {
  final String memberId;
  final double weightKg;
  final DateTime date;

  const WeightLog({
    required this.memberId,
    required this.weightKg,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'weightKg': weightKg,
        'date': date.toIso8601String(),
      };

  factory WeightLog.fromMap(Map<String, dynamic> map) => WeightLog(
        memberId: map['memberId'] as String,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      );
}
