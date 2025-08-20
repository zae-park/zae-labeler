// lib/view_models/sub_view_models/segmentation_labeling_view_model.dart
import 'package:flutter/material.dart';

import '../../../../core/models/label/segmentation_label_model.dart';
import '../label_view_model.dart';
import 'base_labeling_view_model.dart';

/// ViewModel for segmentation labeling mode.
/// Manages pixel-wise label grid, class selection, and grid-to-label conversions.
class SegmentationLabelingViewModel extends LabelingViewModel {
  String? _selectedClass;
  String? get selectedClass => _selectedClass;

  SegmentationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases, super.initialDataList});

  // --- 상태 로직 ---
  @override
  Future<void> postInitialize() async {
    restoreGridFromLabel();
    if (_selectedClass == null && project.classes.isNotEmpty) {
      _selectedClass = project.classes.first;
    }
    await labelManager.refreshStatusFor(dataManager.currentData, (status) {
      dataManager.updateStatus(dataManager.currentData.dataId, status);
    });
    notifyListeners();
  }

  @override
  Future<void> postMove() async {
    restoreGridFromLabel();
    await labelManager.refreshStatusFor(dataManager.currentData, (status) {
      dataManager.updateStatus(dataManager.currentData.dataId, status);
    });
    notifyListeners();
  }

  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = labelManager.currentLabelVM!;
    await labelVM.updateLabel(labelData);
    await labelVM.saveLabel();
    await labelManager.refreshStatusFor(dataManager.currentData, (status) {
      dataManager.updateStatus(dataManager.currentData.dataId, status);
    });
    notifyListeners();
  }

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

    await updateLabel(Segment(indices: selectedPixels, classLabel: _selectedClass!));
  }

  void restoreGridFromLabel() {
    final label = labelManager.currentLabelVM?.labelModel.label;
    if (label is! SegmentationData) return;

    _labelGrid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

    for (var segment in label.segments.values) {
      for (final (x, y) in segment.indices) {
        if (x < _gridSize && y < _gridSize) {
          _labelGrid[y][x] = 1;
        }
      }
    }
  }

  // --- Grid 상태 ---
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
    if (_selectedClass == null) return;

    final labelVM = labelManager.currentLabelVM;
    if (labelVM is SegmentationLabelViewModel) {
      labelVM.addPixel(x, y, _selectedClass!);
    }
  }

  void removePixel(int x, int y) {
    final labelVM = labelManager.currentLabelVM;
    if (labelVM is SegmentationLabelViewModel) {
      labelVM.removePixel(x, y);
    }
  }

  // --- 드래그 선택 박스 ---
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

  // --- 상태 요약 ---
  @override
  int get totalCount => dataManager.totalCount;

  @override
  int get completeCount => dataManager.completeCount;

  @override
  int get warningCount => dataManager.warningCount;

  @override
  int get incompleteCount => dataManager.incompleteCount;

  @override
  double get progressRatio => dataManager.progressRatio;
}
