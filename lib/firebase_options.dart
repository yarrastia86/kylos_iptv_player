// File generated based on Firebase configuration files.
// This file contains platform-specific Firebase options.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhgkaOjnRbUhYhSu9Luz6jv7ylraNnZnU',
    appId: '1:455804258948:android:42b01443760ff5f14f90d1',
    messagingSenderId: '455804258948',
    projectId: 'kylos-iptv-player',
    storageBucket: 'kylos-iptv-player.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCcNe4z8GECDnGr6Kp64j7RZpvxmpCqRhA',
    appId: '1:455804258948:ios:ae6441bee2b595e24f90d1',
    messagingSenderId: '455804258948',
    projectId: 'kylos-iptv-player',
    storageBucket: 'kylos-iptv-player.firebasestorage.app',
    iosClientId: '455804258948-i9rt5km5pr8li2q8bc0o05jfndboccj8.apps.googleusercontent.com',
    iosBundleId: 'com.kylos.iptvPlayer',
  );
}
