import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCVqLH_XU4ga3sANOa3T3yPqBqxaNwB7Dk',
    authDomain: 'zae-labeler.firebaseapp.com',
    projectId: 'zae-labeler',
    storageBucket: 'zae-labeler.firebasestorage.com',
    messagingSenderId: '481999041784',
    appId: '1:481999041784:web:355ae31754e3c7731f370d',
    measurementId: 'G-5QDV4WJ1WL',
  );

  static FirebaseOptions get currentPlatform => web;
}
