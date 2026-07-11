import 'package:flutter/material.dart';
import 'leaderboard_screen.dart';
import 'home_screen.dart';
import 'diet_screen.dart';
import 'exercise_screen.dart';
import 'members_screen.dart';

/// The five permanent bottom tabs: Leaderboard, Tasks, Diet, Exercise,
/// Members. The Admin Panel has no tab — it's reached via a hidden
/// long-press on the Brotherhood title inside the Tasks tab.
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 1; // land on Tasks by default

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard_rounded),
      label: 'Leaderboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline_rounded),
      selectedIcon: Icon(Icons.check_circle_rounded),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_outlined),
      selectedIcon: Icon(Icons.restaurant_rounded),
      label: 'Diet',
    ),
    NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center_rounded),
      label: 'Exercise',
    ),
    NavigationDestination(
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group_rounded),
      label: 'Members',
    ),
  ];

  static const _screens = [
    LeaderboardScreen(),
    HomeScreen(),
    DietScreen(),
    ExerciseScreen(),
    MembersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
        height: 70,
        animationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
