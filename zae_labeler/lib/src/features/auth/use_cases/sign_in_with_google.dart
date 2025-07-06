// 📁 lib/features/auth/use_cases/sign_in_with_google.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInWithGoogleUseCase {
  final FirebaseAuth _auth;

  SignInWithGoogleUseCase(this._auth);

  Future<User?> call() async {
    try {
      if (kIsWeb) {
        final credential = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(credential);
        return result.user;
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _auth.signInWithCredential(credential);
        return result.user;
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }
}
