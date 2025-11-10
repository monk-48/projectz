// Firebase Configuration for Web
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDV-7lAKb6JeA1ooekHK42pnhPqt6jw1r8',
    authDomain: 'projectz-99a48.firebaseapp.com',
    projectId: 'projectz-99a48',
    storageBucket: 'projectz-99a48.firebasestorage.app',
    messagingSenderId: '5479216871',
    appId: '1:5479216871:web:93d54e23edd171becfd442',
    measurementId: 'G-QT8MBTT1HY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDV-7lAKb6JeA1ooekHK42pnhPqt6jw1r8',
    appId: '1:5479216871:android:fd79a20e3953e267cfd442',
    messagingSenderId: '5479216871',
    projectId: 'projectz-99a48',
    storageBucket: 'projectz-99a48.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDV-7lAKb6JeA1ooekHK42pnhPqt6jw1r8',
    appId: '1:5479216871:ios:XXXXX', // Replace with your iOS app ID when you add iOS
    messagingSenderId: '5479216871',
    projectId: 'projectz-99a48',
    storageBucket: 'projectz-99a48.firebasestorage.app',
    iosBundleId: 'com.example.projectz',
  );
}
