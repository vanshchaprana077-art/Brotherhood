import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static final DateTime _start = AppConstants.challengeStart;
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollCtrl = ScrollController();
  // Stored at initState so dispose() can safely call it without context
  late AppProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppProvider>();

    // Default to yesterday if available, otherwise the start date
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (yesterday.isBefore(_start)) {
      _selectedDate = _start.isAfter(today) ? today : _start;
    } else {
      _selectedDate = yesterday;
    }
    // Clamp to valid range
    if (_selectedDate.isBefore(_start)) _selectedDate = _start;
    if (_selectedDate.isAfter(today)) _selectedDate = today;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateRange().isNotEmpty) {
        _loadSelected();
        _scrollToSelected();
      }
    });
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    _provider.clearHistory();
    super.dispose();
  }

  void _loadSelected() {
    _provider.loadHistoryDate(_fmt(_selectedDate));
  }

  void _scrollToSelected() {
    final selectedIdx = _selectedDate.difference(_start).inDays;
    final offset = (selectedIdx * 68.0) - 120;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollCtrl.hasClients) {
        _dateScrollCtrl.animateTo(
          offset.clamp(0.0, _dateScrollCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _display(DateTime d) => DateFormat('EEE, MMM d').format(d);

  List<DateTime> _dateRange() {
    final today = DateTime.now();
    final result = <DateTime>[];
    DateTime d = _start;
    while (!d.isAfter(today)) {
      result.add(d);
      d = d.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final locked = provider.isDateLocked(_fmt(_selectedDate));
        final adminUnlocked = provider.historyDateAdminUnlocked;
        final isToday = _fmt(_selectedDate) == provider.todayKey;

        return Scaffold(
          appBar: AppBar(
            title: const Text('📜 History'),
            actions: [
              // Admin unlock toggle — only shown for past dates
              if (provider.isAdmin && locked)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () =>
                        provider.toggleHistoryAdminUnlock(_fmt(_selectedDate)),
                    icon: Icon(
                      adminUnlocked
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                      size: 18,
                      color: adminUnlocked
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    label: Text(
                      adminUnlocked ? 'Lock' : 'Unlock',
                      style: TextStyle(
                        color: adminUnlocked
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Builder(builder: (context) {
            final dates = _dateRange();
            return Column(
            children: [
              // ── Date strip ─────────────────────────────────────────────────
              dates.isEmpty
                  ? Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.white38, size: 18),
                          SizedBox(width: 10),
                          Text('History starts on July 12, 2026',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )
                  : SizedBox(
                height: 80,
                child: ListView.builder(
                  controller: _dateScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final date = dates[i];
                    final isSelected = _fmt(date) == _fmt(_selectedDate);
                    final isT = _fmt(date) == provider.todayKey;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        _loadSelected();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : isT
                                  ? color.withOpacity(0.15)
                                  : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : isT
                                    ? color.withOpacity(0.4)
                                    : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date),
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Lock status banner ─────────────────────────────────────────
              if (!isToday)
                _LockBanner(
                  locked: locked && !adminUnlocked,
                  adminUnlocked: adminUnlocked,
                  isAdmin: provider.isAdmin,
                ),

              // ── Content ────────────────────────────────────────────────────
              Expanded(
                child: provider.historyLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.historyDate == null
                        ? const Center(
                            child: Text('Select a date',
                                style: TextStyle(color: Colors.white38)))
                        : _HistoryContent(
                            date: _fmt(_selectedDate),
                            displayDate: _display(_selectedDate),
                            historyData: provider.historyData,
                            tasks: provider.tasks,
                            isLocked: locked && !adminUnlocked,
                            canEdit: provider.canEditDate(_fmt(_selectedDate)),
                            isAdmin: provider.isAdmin,
                            provider: provider,
                          ),
              ),
            ],
            );
          }),
        );
      },
    );
  }
}

// ── Lock banner ──────────────────────────────────────────────────────────────

class _LockBanner extends StatelessWidget {
  const _LockBanner({
    required this.locked,
    required this.adminUnlocked,
    required this.isAdmin,
  });

  final bool locked;
  final bool adminUnlocked;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (adminUnlocked) {
      bg = Colors.greenAccent.withOpacity(0.1);
      fg = Colors.greenAccent;
      icon = Icons.lock_open_rounded;
      label = 'Admin unlocked — editing enabled';
    } else if (locked) {
      bg = Colors.orangeAccent.withOpacity(0.08);
      fg = Colors.orangeAccent;
      icon = Icons.lock_rounded;
      label = isAdmin
          ? 'Locked — tap Unlock in top-right to edit'
          : 'Locked — only admin can edit past days';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── History content ──────────────────────────────────────────────────────────

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.date,
    required this.displayDate,
    required this.historyData,
    required this.tasks,
    required this.isLocked,
    required this.canEdit,
    required this.isAdmin,
    required this.provider,
  });

  final String date;
  final String displayDate;
  final Map<String, Map<String, TaskStatus>> historyData;
  final List<DailyTask> tasks;
  final bool isLocked;
  final bool canEdit;
  final bool isAdmin;
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Date heading
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            displayDate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(),

        // Summary row
        _SummaryRow(
          historyData: historyData,
          tasks: tasks,
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // One card per member
        ...Member.all.asMap().entries.map((entry) {
          final i = entry.key;
          final member = entry.value;
          final completions = historyData[member.id] ?? {};
          return _MemberHistoryCard(
            member: member,
            completions: completions,
            tasks: tasks,
            canEdit: canEdit && isAdmin,
            date: date,
            provider: provider,
          )
              .animate()
              .fadeIn(delay: (150 + i * 80).ms)
              .slideY(begin: 0.1);
        }),
      ],
    );
  }
}

// ── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.historyData, required this.tasks});

  final Map<String, Map<String, TaskStatus>> historyData;
  final List<DailyTask> tasks;

  @override
  Widget build(BuildContext context) {
    int totalCompleted = 0;
    int totalPossible = Member.all.length * tasks.length;
    for (final m in Member.all) {
      totalCompleted += (historyData[m.id] ?? {})
          .values
          .where((s) => s == TaskStatus.completed)
          .length;
    }
    final pct =
        totalPossible > 0 ? totalCompleted / totalPossible : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryCell(
              label: 'Group Done',
              value: '$totalCompleted/$totalPossible'),
          _SummaryCell(
              label: 'Avg %',
              value: '${(pct * 100).toStringAsFixed(0)}%'),
          _SummaryCell(
              label: 'Members Active',
              value:
                  '${historyData.values.where((m) => m.isNotEmpty).length}/${Member.all.length}'),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

// ── Member history card ──────────────────────────────────────────────────────

class _MemberHistoryCard extends StatefulWidget {
  const _MemberHistoryCard({
    required this.member,
    required this.completions,
    required this.tasks,
    required this.canEdit,
    required this.date,
    required this.provider,
  });

  final Member member;
  final Map<String, TaskStatus> completions;
  final List<DailyTask> tasks;
  final bool canEdit;
  final String date;
  final AppProvider provider;

  @override
  State<_MemberHistoryCard> createState() => _MemberHistoryCardState();
}

class _MemberHistoryCardState extends State<_MemberHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final completed = widget.completions.values
        .where((s) => s == TaskStatus.completed)
        .length;
    final total = widget.tasks.length;
    final pct = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      widget.member.name[0],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$completed/$total tasks completed',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  // Progress chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: pct >= 1.0
                          ? Colors.greenAccent.withOpacity(0.15)
                          : pct >= 0.5
                              ? Colors.orangeAccent.withOpacity(0.15)
                              : Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pct >= 1.0
                            ? Colors.greenAccent
                            : pct >= 0.5
                                ? Colors.orangeAccent
                                : Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),

          // Expanded task list
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Divider(color: Colors.white.withOpacity(0.07)),
                        const SizedBox(height: 8),
                        ...widget.tasks.map((task) {
                          final status = widget.completions[task.id] ??
                              TaskStatus.pending;
                          return _HistoryTaskRow(
                            task: task,
                            status: status,
                            canEdit: widget.canEdit,
                            onComplete: () =>
                                widget.provider.setHistoryTaskStatus(
                                    widget.member.id,
                                    widget.date,
                                    task.id,
                                    TaskStatus.completed),
                            onMiss: () =>
                                widget.provider.setHistoryTaskStatus(
                                    widget.member.id,
                                    widget.date,
                                    task.id,
                                    TaskStatus.missed),
                          );
                        }),
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

// ── History task row ─────────────────────────────────────────────────────────

class _HistoryTaskRow extends StatelessWidget {
  const _HistoryTaskRow({
    required this.task,
    required this.status,
    required this.canEdit,
    required this.onComplete,
    required this.onMiss,
  });

  final DailyTask task;
  final TaskStatus status;
  final bool canEdit;
  final VoidCallback onComplete;
  final VoidCallback onMiss;

  Color get _statusColor {
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
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(task.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: status == TaskStatus.missed
                    ? Colors.white38
                    : Colors.white,
                decoration: status == TaskStatus.missed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (canEdit) ...[
            _EditBtn(
              icon: Icons.check_rounded,
              color: Colors.greenAccent,
              isActive: status == TaskStatus.completed,
              onTap: onComplete,
            ),
            const SizedBox(width: 6),
            _EditBtn(
              icon: Icons.close_rounded,
              color: Colors.redAccent,
              isActive: status == TaskStatus.missed,
              onTap: onMiss,
            ),
          ] else
            Icon(
              status == TaskStatus.completed
                  ? Icons.check_circle_rounded
                  : status == TaskStatus.missed
                      ? Icons.cancel_rounded
                      : Icons.radio_button_unchecked_rounded,
              color: _statusColor,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _EditBtn extends StatelessWidget {
  const _EditBtn({
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
        duration: const Duration(milliseconds: 180),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color:
              isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.white12,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Icon(icon,
            color: isActive ? color : Colors.white24, size: 15),
      ),
    );
  }
}
