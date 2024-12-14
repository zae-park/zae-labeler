import 'dart:io';

String getTempDirectory() {
  return Directory.systemTemp.path; // 네이티브 환경에서 임시 디렉토리 경로
}
