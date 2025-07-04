// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBM-AB3jRjVieX6UjVyHE6cci36ckvf8-U',
    appId: '1:1031456677182:web:e4ba581f633210222f206f',
    messagingSenderId: '1031456677182',
    projectId: 'travellio-74f79',
    authDomain: 'travellio-74f79.firebaseapp.com',
    storageBucket: 'travellio-74f79.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNILWioVVTS3N65tMetjANzIKIl81Bgrk',
    appId: '1:1031456677182:android:c9fdbc40b17d39a72f206f',
    messagingSenderId: '1031456677182',
    projectId: 'travellio-74f79',
    storageBucket: 'travellio-74f79.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZMVJCgsa2QPJvulmEXh7TS1op6WOO9X8',
    appId: '1:1031456677182:ios:b63864e5212122c12f206f',
    messagingSenderId: '1031456677182',
    projectId: 'travellio-74f79',
    storageBucket: 'travellio-74f79.appspot.com',
    iosBundleId: 'com.example.loginTypesApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBZMVJCgsa2QPJvulmEXh7TS1op6WOO9X8',
    appId: '1:1031456677182:ios:b63864e5212122c12f206f',
    messagingSenderId: '1031456677182',
    projectId: 'travellio-74f79',
    storageBucket: 'travellio-74f79.appspot.com',
    iosBundleId: 'com.example.loginTypesApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBM-AB3jRjVieX6UjVyHE6cci36ckvf8-U',
    appId: '1:1031456677182:web:522adb9087e2a86f2f206f',
    messagingSenderId: '1031456677182',
    projectId: 'travellio-74f79',
    authDomain: 'travellio-74f79.firebaseapp.com',
    storageBucket: 'travellio-74f79.appspot.com',
  );
}
