// lib/src/platform_helpers/share/web_share_helper.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'interface_share_helper.dart';

class WebShareHelper implements ShareHelperInterface {
  bool get _canUseWebShare {
    final nav = html.window.navigator as dynamic;
    return nav != null && nav.share != null;
  }

  @override
  Future<void> shareText(String text) async {
    if (_canUseWebShare) {
      final nav = html.window.navigator as dynamic;
      await nav.share({'text': text});
      return;
    }
    // 폴백: 클립보드 복사 + 토스트/alert
    await html.window.navigator.clipboard?.writeText(text);
    html.window.alert('공유가 지원되지 않아 텍스트를 클립보드에 복사했습니다.');
  }

  @override
  Future<void> shareFile(String filePath, {String? fileName, String? mimeType}) async {
    // Web에선 로컬 파일 경로 공유가 불가 → 안내 후 종료 or 다운로드 링크 제공
    html.window.alert('이 플랫폼에서는 파일 경로 공유가 지원되지 않습니다. 다운로드를 사용하세요.');
  }

  @override
  Future<void> shareFiles(List<String> filePaths, {List<String>? fileNames, String? mimeType}) async {
    html.window.alert('이 플랫폼에서는 여러 파일 공유가 지원되지 않습니다.');
  }

  @override
  Future<void> shareBytes(Uint8List bytes, {String fileName = 'share.bin', String? mimeType}) async {
    // navigator.share의 File 공유는 https+권한 필요, 호환성 이슈가 있으므로
    // 기본은 다운로드 폴백
    final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: url)..download = fileName;
    a.click();
    html.Url.revokeObjectUrl(url);
  }
}
