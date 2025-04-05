import 'package:share_plus/share_plus.dart';

/// ❌ 모바일/데스크탑에서는 웹 텍스트 공유 기능이 없음
Future<void> shareTextOnWeb(String title, String text) async {
  // no-op 또는 예외 처리
}

/// ✅ 모바일에서 파일 공유
Future<void> shareFileOnMobile(String filePath, {String? text}) async {
  await Share.shareXFiles([XFile(filePath)], text: text);
}
