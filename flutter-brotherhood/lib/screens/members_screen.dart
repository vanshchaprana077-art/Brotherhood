import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/member.dart';
import '../models/task.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('👥 Members')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: Member.all.asMap().entries.map((entry) {
              final i = entry.key;
              final member = entry.value;
              final completions = provider.allMembersToday[member.id] ?? {};
              final percent = provider.completionPercent(completions);
              final completed = provider.completedCount(completions);
              final streak = provider.streaks[member.id]?.current ?? 0;
              final isCurrentUser =
                  provider.currentMember?.id == member.id;

              return _MemberCard(
                member: member,
                percent: percent,
                completed: completed,
                total: provider.taskCountFor(member.id),
                streak: streak,
                tasks: provider.tasks,
                completions: completions,
                isCurrentUser: isCurrentUser,
              )
                  .animate()
                  .fadeIn(delay: (i * 80).ms)
                  .slideY(begin: 0.15);
            }).toList(),
          ),
        );
      },
    );
  }
}

class _MemberCard extends StatefulWidget {
  const _MemberCard({
    required this.member,
    required this.percent,
    required this.completed,
    required this.total,
    required this.streak,
    required this.tasks,
    required this.completions,
    required this.isCurrentUser,
  });

  final Member member;
  final double percent;
  final int completed;
  final int total;
  final int streak;
  final List<DailyTask> tasks;
  final Map<String, TaskStatus> completions;
  final bool isCurrentUser;

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isCurrentUser
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.07),
          width: widget.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Avatar with progress ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 32,
                        lineWidth: 4,
                        percent: widget.percent,
                        progressColor: widget.percent >= 1.0
                            ? Colors.greenAccent
                            : widget.percent >= 0.5
                                ? Colors.orangeAccent
                                : color,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 800,
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: color.withOpacity(0.2),
                        child: Text(
                          widget.member.name[0],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.member.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.member.isAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (widget.isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.completed}/${widget.total} tasks · 🔥 ${widget.streak} day streak',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(widget.percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.percent >= 1.0
                              ? Colors.greenAccent
                              : widget.percent >= 0.5
                                  ? Colors.orangeAccent
                                  : Colors.white,
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded tasks
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: Colors.white.withOpacity(0.07)),
                        const SizedBox(height: 8),
                        const Text(
                          "Today's Progress",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.tasks.map((task) {
                            final status = widget.completions[task.id] ??
                                TaskStatus.pending;
                            final statusColor =
                                status == TaskStatus.completed
                                    ? Colors.greenAccent
                                    : status == TaskStatus.missed
                                        ? Colors.redAccent
                                        : Colors.white24;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: statusColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(task.icon,
                                      style:
                                          const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor == Colors.white24
                                          ? Colors.white54
                                          : statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
