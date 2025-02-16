import 'dart:io';
import 'package:mockito/mockito.dart';

class MockPathProvider extends Mock {
  Future<Directory> getApplicationDocumentsDirectory() async {
    return Directory.systemTemp; // 테스트 환경에서는 임시 디렉토리 반환
  }
}
