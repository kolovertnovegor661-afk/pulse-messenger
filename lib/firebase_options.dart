import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvEjiGaLyFle9rEBLeTB9Pa1PtqToYuN0',
    appId: '1:129265111480:android:b503b2f78baee06e733f4d',
    messagingSenderId: '129265111480',
    projectId: 'pulse-6e20a',
    storageBucket: 'pulse-6e20a.firebasestorage.app',
  );
}
