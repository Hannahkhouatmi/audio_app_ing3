import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase par plateforme
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'Plateforme non supportée : $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwPmK_K2KqzqEeB8fkujLNd-lXixZxQQU',
    appId: '1:843877100715:web:e78b776210affb8171bee',
    messagingSenderId: '843877100715',
    projectId: 'audio-app-ing3',
    authDomain: 'audio-app-ing3.firebaseapp.com',
    storageBucket: 'audio-app-ing3.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwPmK_K2KqzqEeB8fkujLNd-lXixZxQQU',
    appId: '1:843877100715:android:726fed15a10affb8171bee',
    messagingSenderId: '843877100715',
    projectId: 'audio-app-ing3',
    storageBucket: 'audio-app-ing3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqGvjBzYqvJCFNbuApuFc1kevSfxZeC7Y',
    appId: '1:843877100715:ios:209b6e13b23c293d171bee',
    messagingSenderId: '843877100715',
    projectId: 'audio-app-ing3',
    storageBucket: 'audio-app-ing3.firebasestorage.app',
    iosBundleId: 'com.ing3.usthb.audioAppIng3',
  );

  /// macOS — même projet Firebase que iOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBqGvjBzYqvJCFNbuApuFc1kevSfxZeC7Y',
    appId: '1:843877100715:ios:209b6e13b23c293d171bee',
    messagingSenderId: '843877100715',
    projectId: 'audio-app-ing3',
    storageBucket: 'audio-app-ing3.firebasestorage.app',
    iosBundleId: 'com.ing3.usthb.audioAppIng3',
  );

  /// Windows — configuration web
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDwPmK_K2KqzqEeB8fkujLNd-lXixZxQQU',
    appId: '1:843877100715:web:e78b776210affb8171bee',
    messagingSenderId: '843877100715',
    projectId: 'audio-app-ing3',
    authDomain: 'audio-app-ing3.firebaseapp.com',
    storageBucket: 'audio-app-ing3.firebasestorage.app',
  );

  /// Linux — configuration web
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDwPmK_K2KqzqEeB8fkujLNd-lXixZxQQU',
    appId: '1:843877100715:web:e78b776210affb8171bee',
    messagingSenderId: '843877100715',
    projectId: 'audio-app-ing3',
    authDomain: 'audio-app-ing3.firebaseapp.com',
    storageBucket: 'audio-app-ing3.firebasestorage.app',
  );
}
