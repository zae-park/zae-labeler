// 📁 lib/features/auth/use_cases/sign_in_with_github.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SignInWithGitHubUseCase {
  final FirebaseAuth _auth;

  SignInWithGitHubUseCase(this._auth);

  Future<User?> call() async {
    try {
      final githubProvider = GithubAuthProvider();
      final result = kIsWeb ? await _auth.signInWithPopup(githubProvider) : await _auth.signInWithProvider(githubProvider);

      return result.user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }
}
