// lib/src/platform_helpers/share/native_share_helper.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'interface_share_helper.dart';
// (필요시) import 'package:share_plus/share_plus.dart';

class ShareHelperImpl implements ShareHelperInterface {
  @override
  Future<void> shareText(String text) async {
    // Share.share(text); // share_plus 예시
    // 플랫폼 채널 직접 구현이면 기존 코드 유지
  }

  @override
  Future<void> shareFile(String filePath, {String? fileName, String? mimeType}) async {
    // Share.shareXFiles([XFile(filePath, mimeType: mimeType, name: fileName)]);
  }

  @override
  Future<void> shareFiles(List<String> filePaths, {List<String>? fileNames, String? mimeType}) async {
    // Share.shareXFiles([
    //   for (int i=0;i<filePaths.length;i++)
    //     XFile(filePaths[i], mimeType: mimeType, name: fileNames != null && i < fileNames.length ? fileNames[i] : null),
    // ]);
  }

  @override
  Future<void> shareBytes(Uint8List bytes, {String fileName = 'share.bin', String? mimeType}) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final f = File(path);
    await f.writeAsBytes(bytes, flush: true);
    await shareFile(path, fileName: fileName, mimeType: mimeType);
  }
}
