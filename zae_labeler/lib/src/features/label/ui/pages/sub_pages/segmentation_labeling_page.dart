// 📁 lib/src/views/pages/sub_pages/segmentation_labeling_page.dart
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/segmentation_labeling_view_model.dart';

import '../../../../../views/widgets/grid_painter.dart';
import '../../../../../views/widgets/shared/viewer_builder.dart';
import 'base_labeling_page.dart';

class SegmentationLabelingPage extends BaseLabelingPage<SegmentationLabelingViewModel> {
  const SegmentationLabelingPage({super.key, required super.project, required super.viewModel, super.onSave});

  /// 기본 뷰어 위에 세그멘테이션 그리드를 얹는 오버레이 방식
  /// Base의 훅 시그니처가 `Widget? buildViewerOverride(T vm)` 라면
  /// `BuildContext context` 인자만 제거하고 동일하게 사용하세요.
  @override
  Widget? buildViewerOverride(BuildContext context, SegmentationLabelingViewModel vm) {
    final dataKey = vm.currentData.dataInfo.id;

    // 기본 뷰어 (Base의 공통 로직을 그대로 재현)
    final defaultViewer = FutureBuilder<void>(
      key: ValueKey(dataKey),
      future: vm.ensureRenderableReadyForCurrent(),
      builder: (context, snap) {
        final src = vm.currentRenderable();
        if (src == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ViewerBuilder.fromSource(source: src, data: vm.currentData);
      },
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: defaultViewer),

        // 세그멘테이션 그리드 오버레이 (pixelMask 예시)
        Positioned.fill(
          child: GridPainterWidget(mode: SegmentationMode.pixelMask, onLabelUpdated: (labeledData) => vm.updateSegmentationGrid(labeledData)),
        ),
      ],
    );
  }

  @override
  Widget buildModeSpecificUI(SegmentationLabelingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        children: [
          const Text('클래스 선택:'),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: vm.selectedClass,
            items: vm.project.classes.map((cls) => DropdownMenuItem<String>(value: cls, child: Text(cls))).toList(),
            onChanged: (newValue) {
              if (newValue != null) vm.setSelectedClass(newValue);
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('선택 라벨 저장'), onPressed: vm.saveCurrentGridAsLabel),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('라벨 초기화'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: vm.clearLabels,
          ),
        ],
      ),
    );
  }

  @override
  void handleNumericKeyInput(SegmentationLabelingViewModel vm, int index) {
    // 숫자키로 빠르게 클래스 선택(원하면 사용)
    if (index >= 0 && index < vm.project.classes.length) {
      vm.setSelectedClass(vm.project.classes[index]);
    }
  }
}
