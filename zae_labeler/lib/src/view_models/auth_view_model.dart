// 📁 lib/src/view_models/auth_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  String? conflictingEmail;
  String? conflictingProvider; // ex: "Google", "GitHub"

  AuthViewModel() {
    _auth.authStateChanges().listen((User? u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final credential = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(credential);
        user = result.user;
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _auth.signInWithCredential(credential);
        user = result.user;
      }

      conflictingEmail = null;
      conflictingProvider = null;

      debugPrint("[Auth] ✅ 로그인 성공: ${user?.uid}");
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      await _handleAuthException(e);
    }
  }

  Future<void> signInWithGitHub() async {
    try {
      final githubProvider = GithubAuthProvider();

      final result = kIsWeb ? await _auth.signInWithPopup(githubProvider) : await _auth.signInWithProvider(githubProvider);
      user = result.user;

      conflictingEmail = null;
      conflictingProvider = null;

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      await _handleAuthException(e);
    }
  }

  // Future<void> signInWithKakao() async {
  //   try {
  //     kakao.OAuthToken token;

  //     if (await kakao.isKakaoTalkInstalled()) {
  //       token = await kakao.UserApi.instance.loginWithKakaoTalk();
  //     } else {
  //       token = await kakao.UserApi.instance.loginWithKakaoAccount();
  //     }

  //     final user = await kakao.UserApi.instance.me();
  //     debugPrint("✅ Kakao 로그인 성공: ${user.kakaoAccount?.email ?? user.id}");

  //     // TODO: 이후 firebase custom token 사용 가능
  //     conflictingEmail = null;
  //     conflictingProvider = null;
  //     notifyListeners();
  //   } catch (e) {
  //     debugPrint('❌ 카카오 로그인 실패: $e');
  //   }
  // }

  Future<void> _handleAuthException(FirebaseAuthException e) async {
    if (e.code == 'account-exists-with-different-credential' && e.email != null) {
      conflictingEmail = e.email;

      try {
        final methods = await _auth.fetchSignInMethodsForEmail(conflictingEmail!);

        if (methods.isNotEmpty) {
          const map = {'google.com': 'Google', 'github.com': 'GitHub'};
          conflictingProvider = map[methods.first] ?? methods.first;
        } else {
          conflictingProvider = "Google 또는 GitHub";
        }
      } catch (e) {
        conflictingProvider = "Google 또는 GitHub"; // fetch 실패 시에도 fallback
      }

      debugPrint("⚠️ 계정 충돌: $conflictingEmail → 이전 로그인 방식은 $conflictingProvider");
    } else {
      debugPrint("❌ 로그인 실패: ${e.code} / ${e.message}");
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    user = null;
    conflictingEmail = null;
    conflictingProvider = null;
    notifyListeners();
  }

  bool get isSignedIn => user != null;
  String get userName => user?.displayName ?? '';
  String get userEmail => user?.email ?? '';
}
