import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyBUO45ArsGwVqcB3fJ9NuIXjNcbKnzGWug",
      authDomain: "regalofficial-daf6c.firebaseapp.com",
      databaseURL: "https://regalofficial-daf6c-default-rtdb.firebaseio.com",
      projectId: "regalofficial-daf6c",
      storageBucket: "regalofficial-daf6c.appspot.com",
      messagingSenderId: "523927463635",
      appId: "1:523927463635:web:816aeb2f9f416705929626",
      measurementId: "G-RRREQHEGJ8");

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBUO45ArsGwVqcB3fJ9NuIXjNcbKnzGWug",
    authDomain: "regalofficial-daf6c.firebaseapp.com",
    projectId: "regalofficial-daf6c",
    storageBucket: "regalofficial-daf6c.appspot.com",
    messagingSenderId: "523927463635",
    appId: "1:523927463635:web:816aeb2f9f416705929626",
  );

  static const FirebaseOptions ios = FirebaseOptions(
      apiKey: "AIzaSyBUO45ArsGwVqcB3fJ9NuIXjNcbKnzGWug",
      authDomain: "regalofficial-daf6c.firebaseapp.com",
      databaseURL: "https://regalofficial-daf6c-default-rtdb.firebaseio.com",
      projectId: "regalofficial-daf6c",
      storageBucket: "regalofficial-daf6c.appspot.com",
      messagingSenderId: "523927463635",
      appId: "1:523927463635:web:816aeb2f9f416705929626",
      measurementId: "G-RRREQHEGJ8");

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    authDomain: 'your-macos-auth-domain',
    projectId: 'your-macos-project-id',
    storageBucket: 'your-macos-storage-bucket',
    messagingSenderId: 'your-macos-messaging-sender-id',
    appId: 'your-macos-app-id',
    iosBundleId: 'your-macos-bundle-id',
  );
}
