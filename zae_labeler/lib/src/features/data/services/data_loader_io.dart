// dart:io 가용 환경(Windows/macOS/Linux/Android/iOS)에서 사용
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'data_loader_interface.dart';
import '../../../core/models/data/data_info.dart';

class IoDataLoader implements DataLoader {
  @override
  Future<String?> loadRaw(DataInfo info) async {
    // 1) 웹 업로드 등에서 base64가 이미 있으면 그대로 반환
    if (info.base64Content != null) return info.base64Content;

    // 2) 네이티브 파일 경로가 있으면 파일에서 로드
    final path = info.filePath;
    if (path == null) return null;

    final ext = p.extension(path).toLowerCase();

    if (ext == '.png' || ext == '.jpg' || ext == '.jpeg') {
      // 이미지 → base64 문자열로 반환
      final bytes = await File(path).readAsBytes();
      return base64Encode(bytes);
    } else {
      // 텍스트(csv/json 등) → 문자열
      if (!File(path).existsSync()) return null;
      return File(path).readAsString();
    }
  }
}
