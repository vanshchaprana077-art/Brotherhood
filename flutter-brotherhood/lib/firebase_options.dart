// ──────────────────────────────────────────────────────────────────────────────
// ⚠️  IMPORTANT: Replace this file with the real firebase_options.dart generated
//    by the FlutterFire CLI BEFORE distributing to your friends.
//
//    Run (after creating your Firebase project):
//      flutter pub global activate flutterfire_cli
//      flutterfire configure --project=<your-firebase-project-id>
//
//    Until then the app will build and launch, but all Firestore calls will
//    fail because these are build-only placeholder credentials.
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
          'Brotherhood only targets Android.\n'
          'Run: flutterfire configure --project=<your-project-id>',
        );
    }
  }

  // ⚠️  PLACEHOLDER — replace via: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderKeyForBuildOnlyNotForRuntime01',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'brotherhood-placeholder',
    storageBucket: 'brotherhood-placeholder.appspot.com',
  );
}
