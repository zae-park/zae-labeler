// lib/src/features/auth/use_cases/sign_in_with_google.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SignInWithGoogleUseCase {
  final FirebaseAuth _auth;
  SignInWithGoogleUseCase(this._auth);

  /// Android/iOS: signInWithProvider(GoogleAuthProvider())
  /// Web:         signInWithPopup(GoogleAuthProvider())
  Future<User?> call() async {
    final provider = GoogleAuthProvider();
    // 필요 시 scope / custom parameters 추가 가능
    // provider.addScope('email');
    // provider.setCustomParameters({'prompt': 'select_account'});

    try {
      UserCredential cred;
      if (kIsWeb) {
        cred = await _auth.signInWithPopup(provider);
      } else {
        cred = await _auth.signInWithProvider(provider);
      }
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }
}
