---
name: Flutter Brotherhood Setup
description: Key constraints and quirks for the Brotherhood Flutter/Firebase app
---

# Flutter Brotherhood Setup

## Workmanager version constraint
Flutter SDK on Replit is 3.29.3. workmanager >=0.9 requires Flutter >=3.32. Keep `workmanager: ^0.7.0` in pubspec.yaml.

**Why:** Upgrading breaks pub get with "requires Flutter SDK version >=3.32.0".

**How to apply:** If anyone bumps workmanager, revert to ^0.7.0. Also: in 0.7.0 the enum is `ExistingWorkPolicy` (not `ExistingPeriodicWorkPolicy`).

## Const color issue
`Colors.white87` is not a compile-time constant in Flutter — cannot be used in `const TextStyle(...)`. Use `Color(0xDEFFFFFF)` instead.

## Firebase credentials
`lib/firebase_options.dart` has placeholder credentials. App builds and compiles but all Firestore calls fail at runtime. To fix: run `flutterfire configure --project=<id>` and replace the file, plus place real `google-services.json` in `android/app/`.

## Task structure
Tasks use `appliesTo: ['vansh']` to scope Vansh-only tasks. Empty `appliesTo` = everyone. Water targets differ: `water_vansh` (5L) for Vansh, `water_gp` (4L) for Govind+Piyush.

## Screens status
- Diet, Exercise, Weekly Progress screens are now fully implemented (were "Coming Soon" stubs)
- Admin screen has 4 tabs: Tasks, Profiles, Weight History, Progress Photos
