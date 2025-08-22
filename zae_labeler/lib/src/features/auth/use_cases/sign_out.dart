// lib/src/features/auth/use_cases/sign_out.dart
import 'package:firebase_auth/firebase_auth.dart';

class SignOutUseCase {
  final FirebaseAuth _auth;
  SignOutUseCase(this._auth);

  Future<void> call() async {
    await _auth.signOut();
  }
}
