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
    return GridPainterWidget(
      mode: SegmentationMode.pixelMask,
      onLabelUpdated: (labeledData) => labelingVM.updateSegmentationGrid(labeledData),
    ); // ✅ Grid Painter 추가
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
