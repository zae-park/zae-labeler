import 'dart:html' as html;

/// ✅ 웹에서 텍스트 공유
Future<void> shareTextOnWeb(String title, String text) async {
  await html.window.navigator.share({
    'title': title,
    'text': text,
  });
}

/// ❌ 웹에서는 파일 공유를 지원하지 않음
Future<void> shareFileOnMobile(String filePath, {String? text}) async {
  // no-op 또는 예외 처리
}
