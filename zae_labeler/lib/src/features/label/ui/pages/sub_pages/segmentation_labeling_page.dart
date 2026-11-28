// lib/src/features/label/ui/pages/sub_pages/segmentation_labeling_page.dart
import 'package:flutter/material.dart';

import '../../../view_models/segmentation_labeling_view_model.dart';
import '../../widgets/segmentation_grid.dart';
import 'base_labeling_page.dart';

class SegmentationLabelingPage extends BaseLabelingPage<SegmentationLabelingViewModel> {
  const SegmentationLabelingPage({super.key, required super.viewModel});

  @override
  Widget buildViewer(BuildContext context, SegmentationLabelingViewModel vm) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: super.buildViewer(context, vm)),
        Positioned.fill(child: SegmentationGrid(viewModel: vm)),
      ],
    );
  }

  @override
  Widget buildModeSpecificUI(BuildContext context, SegmentationLabelingViewModel vm) {
    final classes = vm.project.classes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < classes.length; i++)
            ChoiceChip(
              avatar: CircleAvatar(backgroundColor: segmentationColorFor(i)),
              label: Text('${i + 1}. ${classes[i]}'),
              selected: !vm.isErasing && vm.selectedClass == classes[i],
              onSelected: (_) => vm.setSelectedClass(classes[i]),
            ),
          FilterChip(avatar: const Icon(Icons.auto_fix_normal, size: 18), label: const Text('지우개'), selected: vm.isErasing, onSelected: vm.setErasing),
          ElevatedButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('라벨 초기화'),
            onPressed: vm.clearLabels,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  /// 숫자 키로 클래스 빠르게 선택
  @override
  void handleNumericKeyInput(SegmentationLabelingViewModel vm, int index) {
    if (index >= 0 && index < vm.project.classes.length) {
      vm.setSelectedClass(vm.project.classes[index]);
    }
  }
}
