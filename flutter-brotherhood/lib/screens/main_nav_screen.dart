import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'members_screen.dart';
import 'leaderboard_screen.dart';
import 'admin_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppProvider>().isAdmin;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Calendar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.group_outlined),
        selectedIcon: Icon(Icons.group_rounded),
        label: 'Members',
      ),
      const NavigationDestination(
        icon: Icon(Icons.leaderboard_outlined),
        selectedIcon: Icon(Icons.leaderboard_rounded),
        label: 'Ranks',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
    ];

    final screens = [
      const HomeScreen(),
      const CalendarScreen(),
      const MembersScreen(),
      const LeaderboardScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    final clampedIndex = _index.clamp(0, screens.length - 1);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[clampedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: clampedIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
        height: 70,
        animationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
