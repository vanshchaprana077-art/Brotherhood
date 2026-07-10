import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/member.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('🏅 Leaderboard'),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: 'Completion %'),
                Tab(text: 'Streak 🔥'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _RankList(
                members: provider.leaderboardByCompletion,
                valueBuilder: (m) =>
                    '${(provider.completionPercent(provider.allMembersToday[m.id] ?? {}) * 100).toStringAsFixed(0)}%',
                subtitleBuilder: (m) {
                  final c = provider.completedCount(
                      provider.allMembersToday[m.id] ?? {});
                  return '$c/${provider.tasks.length} tasks today';
                },
                currentMemberId: provider.currentMember?.id,
              ),
              _RankList(
                members: provider.leaderboardByStreak,
                valueBuilder: (m) =>
                    '${provider.streaks[m.id] ?? 0} days',
                subtitleBuilder: (m) {
                  final s = provider.streaks[m.id] ?? 0;
                  if (s == 0) return 'No streak yet';
                  if (s == 1) return '1 day strong!';
                  return '$s days strong! 💪';
                },
                currentMemberId: provider.currentMember?.id,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({
    required this.members,
    required this.valueBuilder,
    required this.subtitleBuilder,
    required this.currentMemberId,
  });

  final List<Member> members;
  final String Function(Member) valueBuilder;
  final String Function(Member) subtitleBuilder;
  final String? currentMemberId;

  static const List<Color> _medalColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFC0C0C0), // Silver
    Color(0xFFCD7F32), // Bronze
    Colors.white38,    // 4th
  ];

  static const List<String> _medals = ['🥇', '🥈', '🥉', '4️⃣'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: members.length,
      itemBuilder: (context, i) {
        final member = members[i];
        final isCurrentUser = member.id == currentMemberId;
        final medalColor = _medalColors[i.clamp(0, 3)];
        final medal = _medals[i.clamp(0, 3)];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: i == 0
                  ? medalColor.withOpacity(0.5)
                  : isCurrentUser
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : Colors.white.withOpacity(0.07),
              width: i == 0 || isCurrentUser ? 1.5 : 1,
            ),
            gradient: i == 0
                ? LinearGradient(
                    colors: [
                      medalColor.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: medalColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    medal,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: medalColor.withOpacity(0.2),
                child: Text(
                  member.name[0],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: medalColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleBuilder(member),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              // Value
              Text(
                valueBuilder(member),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (i * 80).ms)
            .slideX(begin: 0.1);
      },
    );
  }
}
