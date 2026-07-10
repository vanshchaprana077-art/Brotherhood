// ──────────────────────────────────────────────────────────────────────────────
// IMPORTANT: Replace this file with the real firebase_options.dart generated
// by the FlutterFire CLI after you connect your Firebase project.
//
// Run:
//   flutter pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// This will regenerate this file with your real credentials.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Brotherhood only targets Android. '
          'Run: flutterfire configure --project=<your-project-id>',
        );
    }
  }

  // ⚠️  PLACEHOLDER — replace with your real values from flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}
