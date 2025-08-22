// lib/src/platform_helpers/share/interface_share_helper.dart
import 'dart:typed_data';

/// {@template share_helper_interface}
/// 공유 기능의 추상화 레이어.
/// - ViewModel/UseCase는 플랫폼에 상관없이 동일 API만 호출.
/// - 실제 동작은 Web/Native 구현체에서 수행.
/// {@endtemplate}
abstract class ShareHelperInterface {
  /// 텍스트를 공유한다.
  /// - Web: Web Share API(navigator.share) → 미지원시 클립보드 복사/알림 등 폴백
  /// - Native: 시스템 공유 시트
  Future<void> shareText(String text);

  /// 단일 파일(로컬 경로)을 공유한다.
  /// - Web: 파일 경로 개념이 없으므로 미지원/다운로드 트리거로 폴백
  /// - Native: 파일 공유
  Future<void> shareFile(String filePath, {String? fileName, String? mimeType});

  /// 다중 파일을 공유한다.
  /// - Web: 미지원 → 압축/다운로드/텍스트 링크 공유 등으로 폴백 가능
  /// - Native: 여러 파일 공유
  Future<void> shareFiles(List<String> filePaths, {List<String>? fileNames, String? mimeType});

  /// 메모리 상의 바이트를 파일로 취급하여 공유한다.
  /// - Web: Blob 생성 → 다운로드 or Web Share API 지원 시 share
  /// - Native: 임시 파일 생성 후 공유
  Future<void> shareBytes(Uint8List bytes, {String fileName = 'share.bin', String? mimeType});
}
