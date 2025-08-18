// lib/src/platform_helpers/share/stub_share_helper.dart
import 'dart:typed_data';
import 'interface_share_helper.dart';

class ShareHelperImpl implements ShareHelperInterface {
  @override
  Future<void> shareText(String text) async {
    // no-op (로그만 남기거나 Snackbar/Toast로 "미지원" 안내)
  }

  @override
  Future<void> shareFile(String filePath, {String? fileName, String? mimeType}) async {}

  @override
  Future<void> shareFiles(List<String> filePaths, {List<String>? fileNames, String? mimeType}) async {}

  @override
  Future<void> shareBytes(Uint8List bytes, {String fileName = 'share.bin', String? mimeType}) async {}
}
