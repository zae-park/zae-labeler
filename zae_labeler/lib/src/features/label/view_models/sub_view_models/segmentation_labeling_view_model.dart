// lib/view_models/sub_view_models/segmentation_labeling_view_model.dart
import 'package:flutter/material.dart';

import '../../../../core/models/label_model.dart';
import '../../../../core/models/sub_models/segmentation_label_model.dart';
import '../label_view_model.dart';
import 'base_labeling_view_model.dart';

/// ViewModel for segmentation labeling mode.
/// Manages pixel-wise label grid, class selection, and grid-to-label conversions.
class SegmentationLabelingViewModel extends LabelingViewModel {
  String? _selectedClass;
  String? get selectedClass => _selectedClass;

  SegmentationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases, super.initialDataList});

  /// Restores grid from saved label and sets default class if needed
  @override
  Future<void> postInitialize() async {
    restoreGridFromLabel();
    if (_selectedClass == null && project.classes.isNotEmpty) {
      _selectedClass = project.classes.first;
    }
    await refreshStatus(currentUnifiedData.dataId);
  }

  @override
  Future<void> postMove() async {
    restoreGridFromLabel();
    await refreshStatus(currentUnifiedData.dataId);
  }

  // --- Grid 상태 관리 ---
  int _gridSize = 32;
  int get gridSize => _gridSize;

  List<List<int>> _labelGrid = List.generate(32, (_) => List.filled(32, 0));
  List<List<int>> get labelGrid => _labelGrid;

  void setGridSize(int newSize) {
    _gridSize = newSize;
    _labelGrid = List.generate(newSize, (_) => List.filled(newSize, 0));
    notifyListeners();
  }

  void clearLabels() {
    _labelGrid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    notifyListeners();
  }

  void setSelectedClass(String classLabel) {
    _selectedClass = classLabel;
    notifyListeners();
  }

  void updateSegmentationGrid(List<List<int>> labeledData) {
    if (labeledData.length == _gridSize && labeledData[0].length == _gridSize) {
      _labelGrid = labeledData;
      notifyListeners();
    }
  }

  void updateSegmentationLabel(int x, int y, int label) {
    if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
      _labelGrid[y][x] = label;
      notifyListeners();
    }
  }

  void addPixel(int x, int y) {
    final classLabel = _selectedClass;
    if (classLabel == null) return;

    final labelVM = currentLabelVM;
    if (labelVM is SegmentationLabelViewModel) {
      labelVM.addPixel(x, y, classLabel);
    }
  }

  void removePixel(int x, int y) {
    final labelVM = currentLabelVM;
    if (labelVM is SegmentationLabelViewModel) {
      labelVM.removePixel(x, y);
    }
  }

  // --- 박스 선택 드래그 ---
  Offset? _startDrag;
  Offset? _currentPointerPosition;

  Offset? get startDrag => _startDrag;
  Offset? get currentPointerPosition => _currentPointerPosition;

  void startBoxSelection(Offset position) {
    _startDrag = position;
    notifyListeners();
  }

  void updateBoxSelection(Offset position) {
    _currentPointerPosition = position;
    notifyListeners();
  }

  void endBoxSelection() {
    _startDrag = null;
    _currentPointerPosition = null;
    notifyListeners();
  }

  /// Applies label model update and status refresh
  @override
  Future<void> updateLabel(dynamic labelData) async {
    currentLabelVM.updateLabel(labelData);
    await appUseCases.label.single.saveLabel(
      projectId: project.id,
      dataId: currentUnifiedData.dataId,
      dataPath: currentUnifiedData.file?.path ?? '',
      labelModel: currentLabelVM.labelModel,
    );
    await refreshStatus(currentUnifiedData.dataId);
    notifyListeners();
  }

  /// Converts current grid to SegmentationData and saves as label
  Future<void> saveCurrentGridAsLabel() async {
    if (_selectedClass == null) {
      debugPrint("[saveCurrentGridAsLabel] No class selected.");
      return;
    }

    final selectedPixels = <(int, int)>{};
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_labelGrid[y][x] == 1) {
          selectedPixels.add((x, y));
        }
      }
    }

    // final segmentation = SegmentationData(
    //   segments: {_selectedClass!: Segment(indices: selectedPixels, classLabel: _selectedClass!)},
    // );

    await updateLabel(Segment(indices: selectedPixels, classLabel: _selectedClass!));
  }

  /// Restores grid state from saved SegmentationData
  void restoreGridFromLabel() {
    final label = currentLabelVM.labelModel.label;
    if (label is! SegmentationData) return;

    _labelGrid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

    for (var segment in label.segments.values) {
      for (final (x, y) in segment.indices) {
        if (x < _gridSize && y < _gridSize) {
          _labelGrid[y][x] = 1;
        }
      }
    }

    notifyListeners();
  }

  @override
  int get totalCount => unifiedDataList.length;

  @override
  int get completeCount => unifiedDataList.where((e) => e.status == LabelStatus.complete).length;

  @override
  int get warningCount => unifiedDataList.where((e) => e.status == LabelStatus.warning).length;

  @override
  int get incompleteCount => totalCount - completeCount;

  @override
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;
}
