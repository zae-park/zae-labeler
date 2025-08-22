// 📁 views/widgets/shared/viewer_builder.dart
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import '../../../features/label/ui/widgets/viewers/image_viewer.dart';
import '../../../features/label/ui/widgets/viewers/object_viewer.dart';
import '../../../features/label/ui/widgets/viewers/time_series_viewer.dart';

class ViewerBuilder extends StatelessWidget {
  final UnifiedData data;

  const ViewerBuilder({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (data.fileType) {
      case FileType.series:
        return TimeSeriesChart(data: data.seriesData ?? const []);
      case FileType.object:
        {
          final map = data.objectData;
          if (map == null) {
            // JSON 파싱 실패/미로딩 등 → 플레이스홀더
            return const _JsonPlaceholder(message: 'No JSON loaded.');
          }
          if (map.isEmpty) {
            // 공백 파일/빈 객체 → 플레이스홀더
            return const _JsonPlaceholder(message: 'This JSON is empty.');
          }
          // 여기부터만 실제 뷰어로 전달
          return ObjectViewer.fromMap(map);
        }
      case FileType.image:
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
        child: Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      ),
    );
  }
}
