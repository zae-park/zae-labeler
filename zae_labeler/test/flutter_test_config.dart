import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ✅ assets/favicon.png를 로드할 수 있도록 설정
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall methodCall) async {
      if (methodCall.method == 'flutter/assets') {
        return null; // 기본적으로 assets을 mock으로 대체
      }
      return null;
    },
  );

  await testMain();
}
