/// Streak stats for a single member.
class StreakInfo {
  final int current;
  final int longest;
  final int missedDays;

  const StreakInfo({
    this.current = 0,
    this.longest = 0,
    this.missedDays = 0,
  });

  Map<String, dynamic> toMap() => {
        'streak': current,
        'longestStreak': longest,
        'missedDays': missedDays,
      };

  factory StreakInfo.fromMap(Map<String, dynamic> map) => StreakInfo(
        current: (map['streak'] as num?)?.toInt() ?? 0,
        longest: (map['longestStreak'] as num?)?.toInt() ?? 0,
        missedDays: (map['missedDays'] as num?)?.toInt() ?? 0,
      );
}
