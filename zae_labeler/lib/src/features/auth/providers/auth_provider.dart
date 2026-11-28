// lib/src/features/auth/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../use_cases/sign_in_with_github.dart';
import '../use_cases/sign_in_with_google.dart';
import '../use_cases/sign_out.dart';

/// 인증 화면 상태 (불변).
@immutable
class AuthState {
  final User? user;

  /// 다른 제공자로 이미 가입된 이메일로 로그인을 시도했을 때 안내용.
  final String? conflictingEmail;
  final String? conflictingProviderHint;

  const AuthState({this.user, this.conflictingEmail, this.conflictingProviderHint});

  bool get isSignedIn => user != null;
  String get userName => user?.displayName ?? '';
  String get userEmail => user?.email ?? '';

  /// 충돌 안내를 지운 상태.
  AuthState withUser(User? user) => AuthState(user: user);
}

/// Firebase 인증 상태를 구독하고 소셜 로그인/로그아웃을 처리합니다.
///
/// 계정 충돌(`account-exists-with-different-credential`) 시 시도한 자격증명을 보관했다가,
/// 사용자가 기존 제공자로 로그인하면 그 계정에 연결합니다.
class AuthNotifier extends Notifier<AuthState> {
  late FirebaseAuth _auth;
  OAuthCredential? _pendingCredential;

  @override
  AuthState build() {
    _auth = ref.watch(firebaseAuthProvider);
    final sub = _auth.authStateChanges().listen((u) {
      if (u?.uid == state.user?.uid) return;
      state = AuthState(user: u, conflictingEmail: state.conflictingEmail, conflictingProviderHint: state.conflictingProviderHint);
    });
    ref.onDispose(sub.cancel);
    return AuthState(user: _auth.currentUser);
  }

  Future<void> signInWithGoogle() => _signIn(SignInWithGoogleUseCase(_auth).call, providerId: 'google.com');

  Future<void> signInWithGitHub() => _signIn(SignInWithGitHubUseCase(_auth).call, providerId: 'github.com');

  Future<void> signOut() async {
    await SignOutUseCase(_auth)();
    _pendingCredential = null;
    state = const AuthState();
  }

  Future<void> _signIn(Future<User?> Function() signIn, {required String providerId}) async {
    try {
      final user = await signIn();
      await _linkIfPending();
      state = state.withUser(user);
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e, attemptedProviderId: providerId);
    }
  }

  void _handleAuthException(FirebaseAuthException e, {required String attemptedProviderId}) {
    if (e.code == 'account-exists-with-different-credential') {
      final cred = e.credential;
      if (cred is OAuthCredential) _pendingCredential = cred;
      debugPrint('⚠️ 계정 충돌: ${e.email} / attempted=$attemptedProviderId');
      state = AuthState(user: state.user, conflictingEmail: e.email, conflictingProviderHint: '이전에 사용한 로그인 방법으로 먼저 로그인해 주세요.');
    } else {
      debugPrint('❌ 로그인 실패: ${e.code} / ${e.message}');
    }
  }

  Future<void> _linkIfPending() async {
    final cred = _pendingCredential;
    final currentUser = _auth.currentUser;
    if (cred == null || currentUser == null) return;
    try {
      await currentUser.linkWithCredential(cred);
      _pendingCredential = null;
      debugPrint('✅ 계정 링크 완료');
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ 계정 링크 실패: ${e.code} / ${e.message}');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
