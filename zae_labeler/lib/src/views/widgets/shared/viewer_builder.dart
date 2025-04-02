// 📁 views/widgets/viewer_builder.dart
import 'package:flutter/material.dart';
import '../../../models/data_model.dart';
import '../../viewers/image_viewer.dart';
import '../../viewers/object_viewer.dart';
import '../../viewers/time_series_viewer.dart';

class ViewerBuilder extends StatelessWidget {
  final UnifiedData data;

  const ViewerBuilder({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (data.fileType) {
      case FileType.series:
        return TimeSeriesChart(data: data.seriesData ?? []);
      case FileType.object:
        return ObjectViewer.fromMap(data.objectData ?? {});
      case FileType.image:
        return ImageViewer.fromUnifiedData(data);
      default:
        return const Center(child: Text('지원되지 않는 파일 형식입니다.'));
    }
  }
}
