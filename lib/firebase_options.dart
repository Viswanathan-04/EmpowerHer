import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

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
    apiKey: 'AIzaSyBnPLbZm3JLDiBJPCJ3_88FWuo_NzOp4UU',
    appId: '1:1029545035222:web:12d32cc8a11fb70b561077',
    messagingSenderId: '1029545035222',
    projectId: 'empowerher-f63c9',
    authDomain: 'empowerher-f63c9.firebaseapp.com',
    storageBucket: 'empowerher-f63c9.firebasestorage.app',
    measurementId: 'G-6KKY63JXNG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCs1mLMC1dcpBQ6BHyn2zi--JIKJ880v-w',
    appId: '1:1029545035222:android:5aa0d88a8f19de27561077',
    messagingSenderId: '1029545035222',
    projectId: 'empowerher-f63c9',
    storageBucket: 'empowerher-f63c9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjHa3kSfFxkDNwHpcXga9iO9ZnsPFhnh0',
    appId: '1:1029545035222:ios:487697b255625152561077',
    messagingSenderId: '1029545035222',
    projectId: 'empowerher-f63c9',
    storageBucket: 'empowerher-f63c9.firebasestorage.app',
    iosClientId: '1029545035222-7kkl86bkd5o45re5nvkooniuja4rq61v.apps.googleusercontent.com',
    iosBundleId: 'com.example.empowerher',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAjHa3kSfFxkDNwHpcXga9iO9ZnsPFhnh0',
    appId: '1:1029545035222:ios:487697b255625152561077',
    messagingSenderId: '1029545035222',
    projectId: 'empowerher-f63c9',
    storageBucket: 'empowerher-f63c9.firebasestorage.app',
    iosClientId: '1029545035222-7kkl86bkd5o45re5nvkooniuja4rq61v.apps.googleusercontent.com',
    iosBundleId: 'com.example.empowerher',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBnPLbZm3JLDiBJPCJ3_88FWuo_NzOp4UU',
    appId: '1:1029545035222:web:a7af6abb6950a35c561077',
    messagingSenderId: '1029545035222',
    projectId: 'empowerher-f63c9',
    authDomain: 'empowerher-f63c9.firebaseapp.com',
    storageBucket: 'empowerher-f63c9.firebasestorage.app',
    measurementId: 'G-ZGNQ8SW0QE',
  );
}