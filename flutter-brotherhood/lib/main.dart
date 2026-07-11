import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/identity_selection_screen.dart';
import 'screens/main_nav_screen.dart';
import 'services/firebase_service.dart';
import 'models/task.dart';

// ── Background task dispatcher (must be a top-level function) ─────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final service = FirebaseService();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (taskName == _kDailyReset) {
        // 1. Fetch the admin-managed task list from Firestore (single source of
        //    truth — admin defines it once; it repeats automatically every day).
        final tasks = await service.fetchTasks();
        // 2. Seed the fresh daily checklist for every member (idempotent).
        await service.initializeDay(today, tasks);
        // 3. Recalculate & persist streaks for all members.
        await service.recalculateAndSaveAllStreaks(tasks);
      }
    } catch (_) {
      // Swallow — background tasks must not throw
    }
    return Future.value(true);
  });
}

const _kDailyReset = 'brotherhoodDailyReset';

// ── Main ──────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // WorkManager — fires the daily reset task every 24 hours
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    _kDailyReset,
    _kDailyReset,
    frequency: const Duration(hours: 24),
    initialDelay: _timeUntilMidnight(),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const BrotherhoodApp(),
    ),
  );
}

/// Calculates how long until the next midnight so the first run aligns.
Duration _timeUntilMidnight() {
  final now = DateTime.now();
  final midnight =
      DateTime(now.year, now.month, now.day + 1); // next midnight
  return midnight.difference(now);
}

// ── App ───────────────────────────────────────────────────────────────────────

class BrotherhoodApp extends StatelessWidget {
  const BrotherhoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brotherhood',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: _buildDarkTheme(),
      home: const AppRoot(),
    );
  }

  ThemeData _buildDarkTheme() {
    const seedColor = Color(0xFF6C63FF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F0F1A),
      primary: seedColor,
      secondary: const Color(0xFF03DAC6),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardTheme(
        color: const Color(0xFF1A1A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: seedColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: seedColor, width: 1.5),
        ),
      ),
    );
  }
}

// ── App root ──────────────────────────────────────────────────────────────────

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.listenTasks();
      provider.listenTodayCompletions();
      provider.listenAllMembersToday();
      provider.listenStreaks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🏆', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (provider.currentMember == null) {
          return const IdentitySelectionScreen();
        }

        return const MainNavScreen();
      },
    );
  }
}
