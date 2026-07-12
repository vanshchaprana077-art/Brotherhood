import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  // Returns today's plan index (0 = Mon, 6 = Sun)
  static int get _todayIndex => DateTime.now().weekday - 1; // 0=Mon..6=Sun

  @override
  Widget build(BuildContext context) {
    final todayIdx = _todayIndex;
    return DefaultTabController(
      length: _days.length,
      initialIndex: todayIdx,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💪 Exercise Plan'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.white38,
            tabs: _days.map((d) => Tab(text: d.shortName)).toList(),
          ),
        ),
        body: TabBarView(
          children: _days.asMap().entries.map((entry) {
            return _DayView(
              day: entry.value,
              isToday: entry.key == todayIdx,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Exercise {
  final String name;
  final String sets;
  final String reps;
  final String? note;

  const _Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.note,
  });
}

class _DayPlan {
  final String name;
  final String shortName;
  final String focus;
  final String emoji;
  final List<_Exercise> exercises;
  final bool isRest;

  const _DayPlan({
    required this.name,
    required this.shortName,
    required this.focus,
    required this.emoji,
    this.exercises = const [],
    this.isRest = false,
  });
}

const _days = [
  _DayPlan(
    name: 'Monday',
    shortName: 'Mon',
    focus: 'Chest + Front Delts + Side Delts + Arms',
    emoji: '🏋️',
    exercises: [
      _Exercise(name: 'Flat Barbell Bench Press', sets: '4', reps: '8–10'),
      _Exercise(name: 'Incline Dumbbell Press', sets: '3', reps: '10–12'),
      _Exercise(name: 'Cable Chest Fly', sets: '3', reps: '12–15'),
      _Exercise(name: 'Dumbbell Front Raise', sets: '3', reps: '12–15'),
      _Exercise(name: 'Lateral Raise', sets: '4', reps: '15–20'),
      _Exercise(name: 'Seated Arnold Press', sets: '3', reps: '10–12'),
      _Exercise(name: 'Barbell Curl', sets: '3', reps: '10–12', note: 'Arms'),
      _Exercise(name: 'Hammer Curl', sets: '3', reps: '12–15', note: 'Arms'),
      _Exercise(name: 'Tricep Pushdown', sets: '3', reps: '12–15', note: 'Arms'),
      _Exercise(name: 'Skull Crushers', sets: '3', reps: '10–12', note: 'Arms'),
    ],
  ),
  _DayPlan(
    name: 'Tuesday',
    shortName: 'Tue',
    focus: 'Back',
    emoji: '🔙',
    exercises: [
      _Exercise(name: 'Deadlift', sets: '4', reps: '6–8'),
      _Exercise(name: 'Pull-Ups / Lat Pulldown', sets: '4', reps: '8–10'),
      _Exercise(name: 'Barbell Row', sets: '4', reps: '8–10'),
      _Exercise(name: 'Seated Cable Row', sets: '3', reps: '10–12'),
      _Exercise(name: 'Single-Arm Dumbbell Row', sets: '3', reps: '10–12'),
      _Exercise(name: 'Face Pull', sets: '3', reps: '15–20'),
      _Exercise(name: 'Straight-Arm Pulldown', sets: '3', reps: '12–15'),
    ],
  ),
  _DayPlan(
    name: 'Wednesday',
    shortName: 'Wed',
    focus: 'Arms + Rear Delts',
    emoji: '💪',
    exercises: [
      _Exercise(name: 'EZ-Bar Curl', sets: '4', reps: '10–12'),
      _Exercise(name: 'Incline Dumbbell Curl', sets: '3', reps: '10–12'),
      _Exercise(name: 'Concentration Curl', sets: '3', reps: '12–15'),
      _Exercise(name: 'Preacher Curl', sets: '3', reps: '10–12'),
      _Exercise(name: 'Close-Grip Bench Press', sets: '4', reps: '8–10'),
      _Exercise(name: 'Overhead Tricep Extension', sets: '3', reps: '10–12'),
      _Exercise(name: 'Cable Tricep Kickback', sets: '3', reps: '12–15'),
      _Exercise(name: 'Reverse Pec Deck (Rear Delt)', sets: '4', reps: '15–20'),
      _Exercise(name: 'Face Pull', sets: '3', reps: '15–20'),
    ],
  ),
  _DayPlan(
    name: 'Thursday',
    shortName: 'Thu',
    focus: 'Chest + Front Delts + Side Delts + Arms',
    emoji: '🏋️',
    exercises: [
      _Exercise(name: 'Incline Barbell Press', sets: '4', reps: '8–10'),
      _Exercise(name: 'Dumbbell Bench Press', sets: '3', reps: '10–12'),
      _Exercise(name: 'Pec Deck / Machine Fly', sets: '3', reps: '12–15'),
      _Exercise(name: 'Cable Front Raise', sets: '3', reps: '12–15'),
      _Exercise(name: 'Dumbbell Lateral Raise', sets: '4', reps: '15–20'),
      _Exercise(name: 'Machine Shoulder Press', sets: '3', reps: '10–12'),
      _Exercise(name: 'Cable Curl', sets: '3', reps: '12–15', note: 'Arms'),
      _Exercise(name: 'Spider Curl', sets: '3', reps: '10–12', note: 'Arms'),
      _Exercise(name: 'Dips', sets: '3', reps: '10–15', note: 'Arms'),
      _Exercise(name: 'Rope Pushdown', sets: '3', reps: '12–15', note: 'Arms'),
    ],
  ),
  _DayPlan(
    name: 'Friday',
    shortName: 'Fri',
    focus: 'Back',
    emoji: '🔙',
    exercises: [
      _Exercise(name: 'Weighted Pull-Ups', sets: '4', reps: '6–8'),
      _Exercise(name: 'T-Bar Row', sets: '4', reps: '8–10'),
      _Exercise(name: 'Wide-Grip Lat Pulldown', sets: '3', reps: '10–12'),
      _Exercise(name: 'Chest-Supported Row', sets: '3', reps: '10–12'),
      _Exercise(name: 'Cable Row (Wide Grip)', sets: '3', reps: '12–15'),
      _Exercise(name: 'Hyperextension / Back Extension', sets: '3', reps: '12–15'),
    ],
  ),
  _DayPlan(
    name: 'Saturday',
    shortName: 'Sat',
    focus: 'Legs',
    emoji: '🦵',
    exercises: [
      _Exercise(name: 'Barbell Squat', sets: '4', reps: '8–10'),
      _Exercise(name: 'Romanian Deadlift', sets: '4', reps: '10–12'),
      _Exercise(name: 'Leg Press', sets: '4', reps: '12–15'),
      _Exercise(name: 'Leg Extension', sets: '3', reps: '15–20'),
      _Exercise(name: 'Leg Curl', sets: '3', reps: '12–15'),
      _Exercise(name: 'Walking Lunges', sets: '3', reps: '12 each leg'),
      _Exercise(name: 'Standing Calf Raise', sets: '4', reps: '15–20'),
      _Exercise(name: 'Seated Calf Raise', sets: '3', reps: '15–20'),
    ],
  ),
  _DayPlan(
    name: 'Sunday',
    shortName: 'Sun',
    focus: 'Rest & Recovery',
    emoji: '😴',
    isRest: true,
  ),
];

class _DayView extends StatelessWidget {
  const _DayView({required this.day, required this.isToday});
  final _DayPlan day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    if (day.isRest) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day.emoji, style: const TextStyle(fontSize: 72))
                .animate()
                .scale(begin: const Offset(0.5, 0.5))
                .fadeIn(),
            const SizedBox(height: 20),
            const Text(
              'Rest & Recovery Day',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'Recover, stretch, and prepare for next week.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Focus banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(day.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.focus,
                      style: TextStyle(
                        fontSize: 13,
                        color: color.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.greenAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(
                flex: 5,
                child: Text(
                  'Exercise',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  'Sets',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  'Reps',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Exercise rows
        ...day.exercises.asMap().entries.map((entry) {
          final i = entry.key;
          final ex = entry.value;
          return _ExerciseRow(exercise: ex, index: i)
              .animate()
              .fadeIn(delay: (100 + i * 60).ms)
              .slideX(begin: 0.1);
        }),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.index});
  final _Exercise exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = exercise.note != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasNote)
                  Text(
                    exercise.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          // Sets
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                exercise.sets,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Reps
          SizedBox(
            width: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                exercise.reps,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
