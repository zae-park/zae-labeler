import 'package:flutter/material.dart';
import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/grid_painter.dart';
import 'base_labeling_page.dart';

class SegmentationLabelingPage extends BaseLabelingPage<SegmentationLabelingViewModel> {
  const SegmentationLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<SegmentationLabelingViewModel> createState() => _SegmentationLabelingPageState();
}

class _SegmentationLabelingPageState extends BaseLabelingPageState<SegmentationLabelingViewModel> {
  @override
  Widget buildBody(SegmentationLabelingViewModel labelingVM) {
    return Stack(
      children: [
        Expanded(child: _buildViewer(labelingVM)),
        GridPainterWidget(
          mode: SegmentationMode.pixelMask,
          onLabelUpdated: (labeledData) => labelingVM.updateSegmentationGrid(labeledData),
        ),
      ],
    );
  }

  Widget _buildViewer(SegmentationLabelingViewModel labelingVM) {
    return Container(); // 실제 뷰어 로직 추가
  }

  @override
  SegmentationLabelingViewModel createViewModel() {
    return SegmentationLabelingViewModel(project: project, storageHelper: StorageHelper.instance);
  }
}
