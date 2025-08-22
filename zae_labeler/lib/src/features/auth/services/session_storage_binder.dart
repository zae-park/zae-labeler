// lib/src/features/auth/services/session_storage_binder.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../env.dart';
import '../../../platform_helpers/storage/switchable_storage_helper.dart';

class SessionStorageBinder {
  final FirebaseAuth auth;
  final SwitchableStorageHelper storage;
  StreamSubscription<User?>? _sub;

  SessionStorageBinder({required this.auth, required this.storage});

  void start() {
    _sub = auth.authStateChanges().listen((user) async {
      if (isProd && kIsWeb && user != null) {
        // 웹+프로덕션+로그인 → Cloud 로 전환
        await storage.switchToCloud();
      } else {
        // 그 외 → Local 유지/복귀
        await storage.switchToLocal();
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
