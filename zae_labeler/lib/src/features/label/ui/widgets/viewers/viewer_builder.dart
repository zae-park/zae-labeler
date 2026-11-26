// lib/src/features/label/ui/widgets/viewers/viewer_builder.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'image_viewer.dart';
import 'object_viewer.dart';
import 'time_series_viewer.dart';

class ViewerBuilder extends StatelessWidget {
  /// 렌더 소스 (옵션)
  /// - String: Blob/HTTP URL
  /// - Uint8List: in-memory bytes
  final Object? source;

  /// 데이터 메타 (파일 타입/파일명 등)
  final UnifiedData data;

  /// 기존 호환: source 없이 data만 전달
  const ViewerBuilder({super.key, required this.data}) : source = null;

  /// 새 경로: VM/DataManager가 준비한 렌더 소스를 직접 전달
  const ViewerBuilder.fromSource({super.key, required this.source, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (data.fileType) {
      case FileType.series:
        return TimeSeriesChart(data: data.seriesData ?? const []);

      case FileType.object:
        {
          final map = data.objectData;
          if (map == null) {
            return const _JsonPlaceholder(message: 'No JSON loaded.');
          }
          if (map.isEmpty) {
            return const _JsonPlaceholder(message: 'This JSON is empty.');
          }
          return ObjectViewer.fromMap(map);
        }

      case FileType.image:
        // 1) source가 있으면 최우선 사용
        if (source != null) {
          final s = source;
          if (s is String) {
            // Blob/HTTP URL
            // (이미 ImageViewer가 URL 입력용 생성자가 없다면 직접 렌더)
            return Image.network(s, fit: BoxFit.contain);
          } else if (s is Uint8List) {
            return Image.memory(s, fit: BoxFit.contain);
          } else {
            // 예상 외 타입 → 안전한 플레이스홀더
            return const Center(child: CircularProgressIndicator());
          }
        }
        // 2) fallback: 기존 동작 유지
        return ImageViewer.fromUnifiedData(data);

      default:
        return const Center(child: Text('지원되지 않는 파일 형식입니다.'));
    }
  }
}

class _JsonPlaceholder extends StatelessWidget {
  final String message;
  const _JsonPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
