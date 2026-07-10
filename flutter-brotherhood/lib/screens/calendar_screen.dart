import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static final DateTime _start = DateTime(2026, 7, 12);
  DateTime _focusedDay = DateTime.now().isBefore(DateTime(2026, 7, 12))
      ? DateTime(2026, 7, 12)
      : DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final start = _start.subtract(const Duration(days: 1));
      final end = now.add(const Duration(days: 1));
      context.read<AppProvider>().loadCalendarRange(start, end);
    });
  }

  Color _dayColor(AppProvider provider, DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final completions = provider.calendarData[key];
    final taskCount = provider.tasks.length;

    if (completions == null || completions.isEmpty || taskCount == 0) {
      return Colors.transparent;
    }

    final completed =
        completions.values.where((s) => s == TaskStatus.completed).length;
    final missed =
        completions.values.where((s) => s == TaskStatus.missed).length;
    final ratio = completed / taskCount;

    if (ratio == 1.0) return Colors.greenAccent;
    if (missed > completed) return Colors.redAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final selectedCompletions = _selectedDay != null
            ? provider.calendarData[
                    DateFormat('yyyy-MM-dd').format(_selectedDay!)] ??
                {}
            : {};

        return Scaffold(
          appBar: AppBar(title: const Text('📅 Calendar')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            children: [
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: Colors.greenAccent, label: 'All done'),
                  const SizedBox(width: 16),
                  _Legend(color: Colors.orangeAccent, label: 'Partial'),
                  const SizedBox(width: 16),
                  _Legend(color: Colors.redAccent, label: 'Mostly missed'),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 12),

              // Calendar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: TableCalendar(
                  firstDay: _start,
                  lastDay: DateTime(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null && isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                    final start = DateTime(focusedDay.year, focusedDay.month, 1)
                        .subtract(const Duration(days: 7));
                    final end =
                        DateTime(focusedDay.year, focusedDay.month + 1, 0)
                            .add(const Duration(days: 7));
                    provider.loadCalendarRange(start, end);
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultTextStyle: const TextStyle(color: Colors.white70),
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white70,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                    headerPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                        color: Colors.white54, fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(
                        color: Colors.white38, fontWeight: FontWeight.w600),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (ctx, day, focusDay) {
                      final color = _dayColor(provider, day);
                      if (color == Colors.transparent) return null;
                      return Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color.withOpacity(0.5), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              // Selected day detail
              if (_selectedDay != null) ...[
                const SizedBox(height: 20),
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),
                if (selectedCompletions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'No data for this day',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ).animate().fadeIn()
                else
                  ...provider.tasks.map((task) {
                    final status =
                        selectedCompletions[task.id] ?? TaskStatus.pending;
                    final color = status == TaskStatus.completed
                        ? Colors.greenAccent
                        : status == TaskStatus.missed
                            ? Colors.redAccent
                            : Colors.white24;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(task.icon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(task.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                          Icon(
                            status == TaskStatus.completed
                                ? Icons.check_circle_rounded
                                : status == TaskStatus.missed
                                    ? Icons.cancel_rounded
                                    : Icons.radio_button_unchecked_rounded,
                            color: color,
                            size: 22,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms);
                  }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    );
  }
}
