import 'package:flutter/material.dart';
import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import 'base_labeling_page.dart';
import '../../widgets/grid_painter.dart';

class SegmentationLabelingPage extends BaseLabelingPage<SegmentationLabelingViewModel> {
  const SegmentationLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<SegmentationLabelingViewModel> createState() => _SegmentationLabelingPageState();
}

class _SegmentationLabelingPageState extends BaseLabelingPageState<SegmentationLabelingViewModel> {
  @override
  Widget buildModeSpecificUI(SegmentationLabelingViewModel labelingVM) {
    return Column(
      children: [
        // ✅ Class 선택 드롭다운
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('클래스 선택:'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: labelingVM.selectedClass,
                items: labelingVM.project.classes.map((cls) => DropdownMenuItem<String>(value: cls, child: Text(cls))).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    labelingVM.setSelectedClass(newValue);
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ✅ GridPainter
        Expanded(
          child: GridPainterWidget(
            mode: SegmentationMode.pixelMask,
            onLabelUpdated: (labeledData) => labelingVM.updateSegmentationGrid(labeledData),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ Label 적용 및 초기화 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('선택 라벨 저장'),
              onPressed: labelingVM.saveCurrentGridAsLabel,
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('라벨 초기화'),
              onPressed: labelingVM.clearLabels,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  SegmentationLabelingViewModel createViewModel() {
    return SegmentationLabelingViewModel(project: project, storageHelper: StorageHelper.instance);
  }

  @override
  void handleNumericKeyInput(SegmentationLabelingViewModel labelingVM, int index) {
    // if (index < labelingVM.project.classes.length) {
    //   labelingVM.setActiveLabel(index); // ✅ 해당 Label로 Painting 준비
    // }
  }
}
