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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAPt_6UAGwbmgBUtalSNSNIIdNCSEk35vQ',
    appId: '1:768317953973:web:ecd05508d7fcb71a416bfc',
    messagingSenderId: '768317953973',
    projectId: 'qr-attendance-system-def21',
    authDomain: 'qr-attendance-system-def21.firebaseapp.com',
    storageBucket: 'qr-attendance-system-def21.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuyrTtPuDqF8U4xg3GywEMsgf8HO1GDbg',
    appId: '1:768317953973:android:6ca31859028a7ccf416bfc',
    messagingSenderId: '768317953973',
    projectId: 'qr-attendance-system-def21',
    storageBucket: 'qr-attendance-system-def21.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBe87yr6L960EbXDp6wIVsgsuZVZwAu6pg',
    appId: '1:768317953973:ios:0d6c66eb06bd0b9e416bfc',
    messagingSenderId: '768317953973',
    projectId: 'qr-attendance-system-def21',
    storageBucket: 'qr-attendance-system-def21.firebasestorage.app',
    iosBundleId: 'com.example.qrAttendanceSystem',
  );
}
