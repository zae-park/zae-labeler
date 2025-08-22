// lib/src/features/auth/view_models/auth_view_model.dart
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

  // 충돌 안내용
  String? conflictingEmail;
  String? conflictingProviderHint; // 더 이상 정확히 특정 불가 → 힌트/문구만
  OAuthCredential? _pendingCredential; // 나중에 linkWithCredential에 사용

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

  /// 편의 팩토리
  factory AuthViewModel.withDefaultUseCases(FirebaseAuth auth) {
    return AuthViewModel(
      signInWithGoogleUseCase: SignInWithGoogleUseCase(auth),
      signInWithGitHubUseCase: SignInWithGitHubUseCase(auth),
      signOutUseCase: SignOutUseCase(auth),
    );
  }

  bool get isSignedIn => user != null;
  String get userName => user?.displayName ?? '';
  String get userEmail => user?.email ?? '';

  /// Google 로그인 → 성공 후 보류 자격증명 링크 시도
  Future<void> signInWithGoogle() async {
    try {
      user = await _signInWithGoogleUseCase();
      await _linkIfPending();
      _clearConflictHints();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      await _handleAuthException(e, attemptedProviderId: 'google.com');
    }
  }

  /// GitHub 로그인 → 성공 후 보류 자격증명 링크 시도
  Future<void> signInWithGitHub() async {
    try {
      user = await _signInWithGitHubUseCase();
      await _linkIfPending();
      _clearConflictHints();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      await _handleAuthException(e, attemptedProviderId: 'github.com');
    }
  }

  Future<void> signOut() async {
    await _signOutUseCase();
    user = null;
    _pendingCredential = null; // 보류 자격증명 초기화
    _clearConflictHints();
    notifyListeners();
  }

  // ───────────────────────────────── helpers ────────────────────────────────

  void _clearConflictHints() {
    conflictingEmail = null;
    conflictingProviderHint = null;
  }

  /// 계정 충돌 발생 시 보류된 자격증명을 저장했다가,
  /// 사용자가 기존 제공자로 로그인하면 계정 링크를 시도합니다.
  Future<void> _handleAuthException(
    FirebaseAuthException e, {
    required String attemptedProviderId,
  }) async {
    if (e.code == 'account-exists-with-different-credential') {
      // 이 경우, 기존에 다른 provider로 가입된 계정이 존재
      conflictingEmail = e.email;
      // pending(시도했던) provider의 credential을 저장해 두었다가 나중에 link
      final cred = e.credential;
      if (cred is OAuthCredential) {
        _pendingCredential = cred;
      }
      // 어떤 provider로 가입되어 있는지는 더 이상 조회할 수 없음
      // → 사용자에게 "이전에 사용한 로그인 방법으로 먼저 로그인한 뒤 계정 연결"을 유도
      conflictingProviderHint = '이전에 사용한 로그인 방법으로 먼저 로그인해 주세요.';
      debugPrint("⚠️ 계정 충돌: ${e.email} / attempted=$attemptedProviderId");
    } else {
      debugPrint("❌ 로그인 실패: ${e.code} / ${e.message}");
    }
    notifyListeners();
  }

  /// 현재 로그인된 계정에 보류 자격증명 연결
  Future<void> _linkIfPending() async {
    final cred = _pendingCredential;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (cred != null && currentUser != null) {
      try {
        await currentUser.linkWithCredential(cred);
        _pendingCredential = null;
        debugPrint('✅ 계정 링크 완료');
      } on FirebaseAuthException catch (e) {
        // 이미 링크되어 있는 경우 등 예외 무시/로깅
        debugPrint('⚠️ 계정 링크 실패: ${e.code} / ${e.message}');
      }
    }
  }
}
