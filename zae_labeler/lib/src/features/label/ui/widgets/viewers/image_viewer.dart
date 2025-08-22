import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';

class ImageViewer extends StatelessWidget {
  final Uint8List? imageBytes; // 메모리 이미지
  final String? base64String; // base64 (data URL 형태 포함)

  const ImageViewer._({this.imageBytes, this.base64String});

  /// ✅ Base64 문자열로부터 생성
  factory ImageViewer.fromBase64(String base64) => ImageViewer._(base64String: base64);

  /// ✅ 메모리 바이트로부터 생성
  factory ImageViewer.fromBytes(Uint8List bytes) => ImageViewer._(imageBytes: bytes);

  /// ✅ UnifiedData로부터 생성 (새 구조: imageBase64만 신뢰)
  factory ImageViewer.fromUnifiedData(UnifiedData u) {
    if (u.fileType != FileType.image) {
      return const ImageViewer._();
    }
    final b64 = u.imageBase64;
    if (b64 != null && b64.isNotEmpty) {
      return ImageViewer.fromBase64(b64);
    }
    // 이미지인데 base64가 비어있다면, 로더/서비스에서 채워지게 설계되어야 함.
    // (UI에서 파일을 직접 읽지 않음)
    return const ImageViewer._();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes ?? _safeDecode(base64String);
    if (bytes == null) {
      return const Center(child: Text('No image data available.'));
    }
    return Padding(padding: const EdgeInsets.all(8.0), child: Image.memory(bytes, fit: BoxFit.contain));
  }

  // ----- 내부 유틸 -----

  /// data URL('data:image/png;base64,...')도 허용하는 안전 디코더
  static Uint8List? _safeDecode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    final s = _stripDataUrlPrefix(b64);
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  /// 'data:*;base64,' 접두어 제거
  static String _stripDataUrlPrefix(String s) {
    final i = s.indexOf(',');
    if (s.startsWith('data:') && i != -1) {
      return s.substring(i + 1);
    }
    return s;
  }
}
