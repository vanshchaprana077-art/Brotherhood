# Brotherhood

A daily discipline tracker for Vansh, Govind, and Piyush — synced in real time via Firebase Firestore. Built in Flutter targeting Android.

## Stack

- **Flutter 3.29.3** (Dart), targeting Android (`com.brotherhood.app`)
- **Firebase**: Cloud Firestore (database) + Firebase Storage (progress photos)
- **State**: `provider` (ChangeNotifier)
- **Background tasks**: `workmanager ^0.7.0`
- **Notifications**: `flutter_local_notifications`
- **UI**: `flutter_animate`, `google_fonts`, `table_calendar`, `percent_indicator`

## Run & Build

```bash
cd flutter-brotherhood

# Install dependencies
flutter pub get

# Analyze for errors
flutter analyze

# Debug APK (fast, for testing)
flutter build apk --debug

# Release APK (for sharing)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Firebase Setup (Required Before Running)

The file `lib/firebase_options.dart` contains **placeholder credentials** — the app will build but Firestore calls will fail until you replace it:

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Cloud Firestore (Production mode)
3. Add an Android app with package name `com.brotherhood.app`
4. Download `google-services.json` → place at `android/app/google-services.json`
5. Run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-firebase-project-id>
   ```
   This overwrites `lib/firebase_options.dart` with real credentials.

## App Structure

### Members
- **Vansh** (Admin) — 5L water, extra tasks (Business, Coding, Learn French, etc.)
- **Govind** — 4L water, common tasks only
- **Piyush** — 4L water, common tasks only

### Challenge
- Start: **13 July 2026**
- Duration: 100 days
- Admin password: stored in `lib/constants.dart`

### Bottom Tabs
| Tab | Screen |
|-----|--------|
| Leaderboard | Ranked by completion % then streak |
| Tasks | Home dashboard + daily checklist |
| Diet | 7-meal daily plan (expandable cards) |
| Exercise | Weekly workout split (Mon–Sun tabs) |
| Members | Per-member progress cards |

### Key Screens
- `lib/screens/home_screen.dart` — Dashboard + task checklist
- `lib/screens/diet_screen.dart` — Meal plan timeline
- `lib/screens/exercise_screen.dart` — Workout schedule by day
- `lib/screens/weekly_progress_screen.dart` — Progress photo upload
- `lib/screens/admin_screen.dart` — Tasks / Profiles / Weight History / Photos (password-gated)
- `lib/screens/history_screen.dart` — Past day viewer (admin can edit/unlock)
- `lib/screens/calendar_screen.dart` — Color-coded calendar dots

### Firestore Collections
| Collection | Purpose |
|------------|---------|
| `tasks_config` | Admin-managed task list |
| `completions/{memberId}_{date}` | Daily task status per member |
| `day_records/{date}` | Seeding idempotency flag |
| `streaks/{memberId}` | Persisted streak stats |
| `profiles/{memberId}` | Height, weight, goal, age |
| `weight_logs` | Weight history per member |
| `progress_photos/{memberId}_week{N}` | Weekly body photos |
| `admin_unlocks/{date}` | Past-date edit permissions |

## Where Things Live

- `lib/constants.dart` — Challenge start date, duration, admin password, photo interval
- `lib/models/task.dart` — `DailyTask` defaults (full canonical task list with `appliesTo`)
- `lib/providers/app_provider.dart` — Central state; all `withTimeout()` guards loading
- `lib/services/firebase_service.dart` — All Firestore + Storage operations

## Architecture Decisions

- **`withTimeout` everywhere**: every Firestore call at startup is capped at 5s so the app never hangs on a slow connection (fixes the loading-forever bug).
- **Per-member task filtering**: tasks carry an `appliesTo` list; empty = everyone. Vansh has extra tasks; water target differs per member.
- **Workmanager 0.7.0** (not 0.9.x): Replit's Flutter SDK is 3.29.3; workmanager ≥0.9 requires Flutter ≥3.32. Use `ExistingWorkPolicy` (not `ExistingPeriodicWorkPolicy`) in this version.
- **Admin panel is password-gated**, not member-gated — anyone with the password can access it regardless of selected identity.
- **Progress photos** are Firebase Storage URLs stored in Firestore; only admin can view all members' photos.

## Gotchas

- `workmanager` must stay at `^0.7.0` — newer versions require Flutter ≥3.32.
- `ExistingPeriodicWorkPolicy` does not exist in workmanager 0.7.0 — use `ExistingWorkPolicy`.
- `Colors.white87` is not a compile-time constant in Flutter — use `Color(0xDEFFFFFF)` in `const` contexts.
- The `assets/icon/icon.png` is a placeholder (512×512 solid purple). Replace it with a real icon, then run `flutter pub run flutter_launcher_icons` to apply it.
- `firebase_options.dart` has placeholder credentials — the app must be built with real Firebase config before distribution.

## User Preferences

- Preserve all working Firebase/Firestore functionality when making changes.
- Do not remove or restructure existing working code without asking.
- Keep task implementations step-by-step with `flutter analyze` verification after changes.
