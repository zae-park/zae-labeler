import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPathProvider {
  static void setup() {
    TestWidgetsFlutterBinding.ensureInitialized(); // Flutter 테스트 바인딩 초기화

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path; // ✅ 임시 디렉토리 반환
        }
        return null;
      },
    );
  }
}
