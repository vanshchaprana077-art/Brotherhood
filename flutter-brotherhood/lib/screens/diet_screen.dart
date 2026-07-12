import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🥗 Diet Plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: _meals.asMap().entries.map((entry) {
          return _MealCard(meal: entry.value, index: entry.key)
              .animate()
              .fadeIn(delay: (entry.key * 80).ms)
              .slideY(begin: 0.15);
        }).toList(),
      ),
    );
  }
}

class _Meal {
  final String time;
  final String label;
  final String icon;
  final List<String> items;
  final String? note;

  const _Meal({
    required this.time,
    required this.label,
    required this.icon,
    required this.items,
    this.note,
  });
}

const _meals = [
  _Meal(
    time: 'After Gym',
    label: 'Meal 1',
    icon: '🥚',
    items: [
      '100g Daliya',
      'Milk',
      '1 Spoon Ghee',
      '5 Eggs',
    ],
    note: 'Post-workout recovery meal',
  ),
  _Meal(
    time: 'Mid Morning',
    label: 'Meal 2 — Bulking Shake',
    icon: '🍌',
    items: [
      '2 Bananas',
      '1 Glass Milk',
      '2 Scoops Oats',
      '1 Spoon Peanut Butter',
      'Cashew',
      'Almond',
      'Raisins',
    ],
    note: 'Blend everything together',
  ),
  _Meal(
    time: 'Lunch',
    label: 'Meal 3',
    icon: '🍚',
    items: [
      '300g Rice',
      'Dal',
      'Salad',
      '200g Curd',
    ],
  ),
  _Meal(
    time: 'Evening',
    label: 'Meal 4 — Bulking Shake',
    icon: '🥤',
    items: [
      '2 Bananas',
      '1 Glass Milk',
      '2 Scoops Oats',
      '1 Spoon Peanut Butter',
      'Cashew',
      'Almond',
      'Raisins',
    ],
    note: 'Same as Meal 2',
  ),
  _Meal(
    time: 'Dinner',
    label: 'Meal 5',
    icon: '🍗',
    items: [
      '3 Eggs',
      '150g Chicken Breast',
    ],
    note: 'High protein dinner',
  ),
  _Meal(
    time: 'Night',
    label: 'Meal 6',
    icon: '🫓',
    items: [
      '3–4 Roti',
      'Home Sabzi',
    ],
  ),
  _Meal(
    time: 'Before Sleep',
    label: 'Before Bed',
    icon: '🥛',
    items: [
      '1 Glass Milk',
    ],
    note: 'Slow-digesting casein protein',
  ),
];

class _MealCard extends StatefulWidget {
  const _MealCard({required this.meal, required this.index});
  final _Meal meal;
  final int index;

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _expanded = false;

  // Colors cycling through accent palette
  static const List<Color> _accentColors = [
    Color(0xFF6C63FF),
    Color(0xFF03DAC6),
    Color(0xFFFFB74D),
    Color(0xFF6C63FF),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF03DAC6),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _accentColors[widget.index % _accentColors.length];
    final meal = widget.meal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      meal.time,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (meal.note != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            meal.note!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(meal.icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Divider(color: Colors.white.withOpacity(0.06)),
                          const SizedBox(height: 8),
                          ...meal.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xDEFFFFFF),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
