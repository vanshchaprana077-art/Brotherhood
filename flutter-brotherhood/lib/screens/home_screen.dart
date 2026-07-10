import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';

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
        final percent = provider.completionPercent(completions);
        final remaining = provider.remainingCount(completions);
        final streak = provider.streaks[member.id] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆 '),
                const Text('Brotherhood'),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.init();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                // ── Header card ────────────────────────────────────────────
                _HeaderCard(
                  dateStr: dateStr,
                  memberName: member.name,
                  percent: percent,
                  remaining: remaining,
                  streak: streak,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                const SizedBox(height: 24),

                // ── Tasks section ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Tasks",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${provider.completedCount(completions)}/${provider.tasks.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),

                if (provider.tasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No tasks configured yet'),
                    ),
                  )
                else
                  ...provider.tasks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final task = entry.value;
                    final status = provider.statusOf(task.id);
                    return _TaskCard(
                      task: task,
                      status: status,
                      onComplete: () =>
                          provider.setTaskStatus(task.id, TaskStatus.completed),
                      onMiss: () =>
                          provider.setTaskStatus(task.id, TaskStatus.missed),
                    )
                        .animate()
                        .fadeIn(delay: (300 + i * 60).ms)
                        .slideX(begin: 0.15);
                  }),
              ],
            ),
          ),
        );
      },
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
  });

  final String dateStr;
  final String memberName;
  final double percent;
  final int remaining;
  final int streak;

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
          Text(
            dateStr,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hey, $memberName 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                      icon: Icons.pending_actions_rounded,
                      label: 'Remaining',
                      value: '$remaining tasks',
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '$streak days',
                      color: Colors.deepOrangeAccent,
                    ),
                  ],
                ),
              ),
            ],
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
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
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
  });

  final DailyTask task;
  final TaskStatus status;
  final VoidCallback onComplete;
  final VoidCallback onMiss;

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor().withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        subtitle: status != TaskStatus.pending
            ? Text(
                status == TaskStatus.completed ? '✓ Completed' : '✗ Missed',
                style: TextStyle(
                  color: _statusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            : const Text(
                'Pending',
                style: TextStyle(color: Colors.white38, fontSize: 12),
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
  final VoidCallback onTap;

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
          color: isActive ? color : Colors.white24,
          size: 18,
        ),
      ),
    );
  }
}
