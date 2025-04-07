import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  AuthViewModel() {
    _auth.authStateChanges().listen((User? u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ✅ Web 로그인 방식
        GoogleAuthProvider authProvider = GoogleAuthProvider();

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(authProvider);
        user = userCredential.user;
      } else {
        // ✅ Native(Android/iOS) 로그인 방식
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          print('🚫 로그인 취소됨 또는 팝업 차단');
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        user = userCredential.user;
      }

      notifyListeners();
    } catch (e) {
      print('🔥 로그인 실패: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  bool get isSignedIn => user != null;
  String get userName => user?.displayName ?? '';
  String get userEmail => user?.email ?? '';
}
