import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'weekly_progress_screen.dart';
import 'admin_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final member = provider.currentMember;
        if (member == null) return const SizedBox();

        final now = DateTime.now();
        final dateStr = DateFormat('EEEE, MMMM d').format(now);
        final completions = provider.todayCompletions;
        final percent = provider.completionPercent(completions, memberId: member.id);
        final remaining = provider.remainingCount(completions, memberId: member.id);
        final streak = provider.streaks[member.id];
        final myTasks = provider.tasksForMember(member.id);

        // Split tasks into pending/completed for instant visual feedback
        final pendingTasks = myTasks
            .where((t) => provider.statusOf(t.id) == TaskStatus.pending)
            .toList();
        final doneTasks = myTasks
            .where((t) => provider.statusOf(t.id) != TaskStatus.pending)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onLongPress: () => _openAdmin(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏆 '),
                  Text('Brotherhood'),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Weekly Progress Photos',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeeklyProgressScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: 'Calendar',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              // Admin shortcut — always visible so it's discoverable
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: 'Admin Panel',
                onPressed: () => _openAdmin(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => provider.refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                _HeaderCard(
                  dateStr: dateStr,
                  memberName: member.name,
                  percent: percent,
                  remaining: remaining,
                  streak: streak?.current ?? 0,
                  longestStreak: streak?.longest ?? 0,
                  score: provider.completedCount(completions, memberId: member.id),
                  dailyRank: provider.dailyRank,
                  currentDay: provider.currentDayNumber,
                  daysRemaining: provider.daysRemaining,
                  challengeStarted: provider.challengeStarted,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                const SizedBox(height: 24),

                // ── Pending tasks section ─────────────────────────────────
                if (myTasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No tasks configured yet.\nLong-press the title or tap ⚙️ to open Admin.',
                        style: TextStyle(color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pendingTasks.isEmpty ? "Today's Tasks" : 'Pending',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${provider.completedCount(completions, memberId: member.id)}/${myTasks.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 12),

                  if (pendingTasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 12),
                          Text(
                            'All tasks completed!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95))
                  else
                    ...pendingTasks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final task = entry.value;
                      final status = provider.statusOf(task.id);
                      final locked = !provider.canEditDate(provider.todayKey);
                      return _TaskCard(
                        task: task,
                        status: status,
                        onComplete: locked
                            ? null
                            : () => provider.setTaskStatus(task.id, TaskStatus.completed),
                        onMiss: locked
                            ? null
                            : () => provider.setTaskStatus(task.id, TaskStatus.missed),
                      )
                          .animate()
                          .fadeIn(delay: (300 + i * 60).ms)
                          .slideX(begin: 0.15);
                    }),

                  // ── Completed/missed tasks section ─────────────────────
                  if (doneTasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Completed (${doneTasks.where((t) => provider.statusOf(t.id) == TaskStatus.completed).length})'
                          '${doneTasks.any((t) => provider.statusOf(t.id) == TaskStatus.missed) ? '  ✗ Missed (${doneTasks.where((t) => provider.statusOf(t.id) == TaskStatus.missed).length})' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),

                    const SizedBox(height: 8),

                    ...doneTasks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final task = entry.value;
                      final status = provider.statusOf(task.id);
                      final locked = !provider.canEditDate(provider.todayKey);
                      return _TaskCard(
                        task: task,
                        status: status,
                        onComplete: locked
                            ? null
                            : () => provider.setTaskStatus(task.id, TaskStatus.completed),
                        onMiss: locked
                            ? null
                            : () => provider.setTaskStatus(task.id, TaskStatus.missed),
                        dimmed: true,
                      )
                          .animate()
                          .fadeIn(delay: (i * 40).ms);
                    }),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.dateStr,
    required this.memberName,
    required this.percent,
    required this.remaining,
    required this.streak,
    required this.longestStreak,
    required this.score,
    required this.dailyRank,
    required this.currentDay,
    required this.daysRemaining,
    required this.challengeStarted,
  });

  final String dateStr;
  final String memberName;
  final double percent;
  final int remaining;
  final int streak;
  final int longestStreak;
  final int score;
  final int dailyRank;
  final int currentDay;
  final int daysRemaining;
  final bool challengeStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.25),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              if (challengeStarted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day $currentDay',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hey, $memberName 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (!challengeStarted) ...[
            const SizedBox(height: 6),
            Text(
              'Challenge starts in $daysRemaining day${daysRemaining == 1 ? '' : 's'} 🔥',
              style: const TextStyle(fontSize: 13, color: Colors.orangeAccent),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CircularPercentIndicator(
                  radius: 52,
                  lineWidth: 8,
                  percent: percent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'done',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                  progressColor: percent >= 1.0
                      ? Colors.greenAccent
                      : percent >= 0.5
                          ? Colors.orangeAccent
                          : color,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1000,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      icon: Icons.star_rounded,
                      label: "Today's Score",
                      value: '$score pts',
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      icon: Icons.emoji_events_rounded,
                      label: 'Daily Rank',
                      value: dailyRank > 0 ? '#$dailyRank' : '—',
                      color: Colors.tealAccent,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '$streak (best $longestStreak)',
                      color: Colors.deepOrangeAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.pending_actions_rounded,
                  label: 'Remaining',
                  value: '$remaining tasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.flag_rounded,
                  label: 'Days Left',
                  value: '$daysRemaining',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.white54)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
            Text(value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.status,
    required this.onComplete,
    required this.onMiss,
    this.dimmed = false,
  });

  final DailyTask task;
  final TaskStatus status;
  final VoidCallback? onComplete;
  final VoidCallback? onMiss;
  final bool dimmed;

  Color _statusColor() {
    switch (status) {
      case TaskStatus.completed:
        return Colors.greenAccent;
      case TaskStatus.missed:
        return Colors.redAccent;
      case TaskStatus.pending:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: dimmed ? 0.65 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _statusColor().withOpacity(0.4)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(task.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: status == TaskStatus.missed
                  ? TextDecoration.lineThrough
                  : null,
              color: status == TaskStatus.missed
                  ? Colors.white38
                  : Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status != TaskStatus.pending)
                Text(
                  status == TaskStatus.completed ? '✓ Completed' : '✗ Missed',
                  style: TextStyle(
                    color: _statusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const Text(
                  'Pending',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              if (task.targetValue != null)
                Text(
                  'Target: ${task.targetValue}',
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionBtn(
                icon: Icons.check_rounded,
                color: Colors.greenAccent,
                isActive: status == TaskStatus.completed,
                onTap: onComplete,
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.close_rounded,
                color: Colors.redAccent,
                isActive: status == TaskStatus.missed,
                onTap: onMiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : Colors.white12,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null ? Colors.white12 : (isActive ? color : Colors.white24),
          size: 18,
        ),
      ),
    );
  }
}
