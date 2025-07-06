import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../use_cases/sign_in_with_google.dart';
import '../use_cases/sign_in_with_github.dart';
import '../use_cases/sign_out.dart';

class AuthViewModel extends ChangeNotifier {
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithGitHubUseCase _signInWithGitHubUseCase;
  final SignOutUseCase _signOutUseCase;

  User? user;
  String? conflictingEmail;
  String? conflictingProvider;

  AuthViewModel({
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithGitHubUseCase signInWithGitHubUseCase,
    required SignOutUseCase signOutUseCase,
  })  : _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _signInWithGitHubUseCase = signInWithGitHubUseCase,
        _signOutUseCase = signOutUseCase {
    FirebaseAuth.instance.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      user = await _signInWithGoogleUseCase();
      conflictingEmail = null;
      conflictingProvider = null;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      await _handleAuthException(e);
    }
  }

  Future<void> signInWithGitHub() async {
    try {
      user = await _signInWithGitHubUseCase();
      conflictingEmail = null;
      conflictingProvider = null;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      await _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _signOutUseCase();
    user = null;
    conflictingEmail = null;
    conflictingProvider = null;
    notifyListeners();
  }

  bool get isSignedIn => user != null;
  String get userName => user?.displayName ?? '';
  String get userEmail => user?.email ?? '';

  Future<void> _handleAuthException(FirebaseAuthException e) async {
    if (e.code == 'account-exists-with-different-credential' && e.email != null) {
      conflictingEmail = e.email;
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(conflictingEmail!);
        const map = {'google.com': 'Google', 'github.com': 'GitHub'};
        conflictingProvider = methods.isNotEmpty ? map[methods.first] ?? methods.first : "Google 또는 GitHub";
      } catch (_) {
        conflictingProvider = "Google 또는 GitHub";
      }

      debugPrint("⚠️ 계정 충돌: $conflictingEmail → 이전 로그인 방식은 $conflictingProvider");
    } else {
      debugPrint("❌ 로그인 실패: ${e.code} / ${e.message}");
    }
    notifyListeners();
  }
}
