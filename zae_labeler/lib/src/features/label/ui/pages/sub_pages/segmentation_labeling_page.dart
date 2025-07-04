// 📁 lib/src/views/pages/sub_pages/segmentation_labeling_page.dart
import 'package:flutter/material.dart';

import '../../../../project/models/project_model.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../../../../views/widgets/grid_painter.dart';
import 'base_labeling_page.dart';

class SegmentationLabelingPage extends BaseLabelingPage<SegmentationLabelingViewModel> {
  const SegmentationLabelingPage({Key? key, required Project project, required SegmentationLabelingViewModel viewModel})
      : super(key: key, project: project, viewModel: viewModel);

  @override
  Widget buildViewer(SegmentationLabelingViewModel vm) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: super.buildViewer(vm)),
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
              onPressed: vm.clearLabels,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)),
        ],
      ),
    );
  }

  @override
  void handleNumericKeyInput(SegmentationLabelingViewModel vm, int index) {
    // 선택적: 숫자 키에 대응하는 클래스 빠르게 선택하고 싶을 경우 구현 가능
  }
}
