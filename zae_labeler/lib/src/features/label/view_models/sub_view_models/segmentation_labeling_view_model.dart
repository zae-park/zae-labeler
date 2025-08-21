// 📁 lib/src/features/label/view_models/sub_view_models/segmentation_labeling_view_model.dart
import 'package:flutter/material.dart';

import 'base_labeling_view_model.dart';
import '../label_view_model.dart' show SegmentationLabelViewModel; // 타입 확인용

import 'package:zae_labeler/src/core/models/label/label_model.dart'; // barrel: SegmentationData/Segment 포함

/// ViewModel for segmentation labeling mode.
/// Manages pixel-wise label grid, class selection, and grid-to-label conversions.
class SegmentationLabelingViewModel extends LabelingViewModel {
  SegmentationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases});

  // ───────────────────────────────────────────────────────────────────────────
  // 선택된 클래스
  // ───────────────────────────────────────────────────────────────────────────
  String? _selectedClass;
  String? get selectedClass => _selectedClass;

  // ───────────────────────────────────────────────────────────────────────────
  // 초기화/이동 훅
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Future<void> postInitialize() async {
    // 첫 데이터의 라벨을 그리드로 복원
    _restoreGridFromLabel();

    // 초기 선택 클래스 없으면 첫 클래스로 설정
    if (_selectedClass == null && project.classes.isNotEmpty) {
      _selectedClass = project.classes.first;
    }

    notifyListeners();
  }

  @override
  Future<void> postMove() async {
    // 현재 데이터 변경 시 그리드 상태를 라벨에서 복원
    _restoreGridFromLabel();
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Grid 상태
  // ───────────────────────────────────────────────────────────────────────────
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
    if (labeledData.isEmpty) return;
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

  // ───────────────────────────────────────────────────────────────────────────
  // 라벨 <-> 그리드 동기화
  // ───────────────────────────────────────────────────────────────────────────
  /// 현재 선택된 클래스에 대해, 그리드의 1값 픽셀을 SegmentationData로 변환 후 저장
  Future<void> saveCurrentGridAsLabel() async {
    if (_selectedClass == null) {
      debugPrint("[saveCurrentGridAsLabel] No class selected.");
      return;
    }

    // 1) 그리드 → 픽셀 집합
    final selectedPixels = <(int, int)>{};
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_labelGrid[y][x] == 1) {
          selectedPixels.add((x, y));
        }
      }
    }

    // 2) 픽셀 집합 → SegmentationData
    final seg = SegmentationData(segments: {
      _selectedClass!: Segment(indices: selectedPixels, classLabel: _selectedClass!),
    });

    // 3) 베이스 VM의 updateLabel을 사용 (매퍼 → 저장 → 요약 재계산)
    await updateLabel(seg);
  }

  /// 현재 라벨 모델의 SegmentationData를 그리드에 반영
  void _restoreGridFromLabel() {
    final seg = labelManager.currentLabelVM?.labelModel.label;
    if (seg is! SegmentationData) {
      _labelGrid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
      return;
    }

    final grid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    for (final segment in seg.segments.values) {
      for (final (x, y) in segment.indices) {
        if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
          grid[y][x] = 1;
        }
      }
    }
    _labelGrid = grid;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 픽셀 편집 (개별 라벨 VM에 위임: 세이브/요약은 매 픽셀마다 하지 않음)
  // ───────────────────────────────────────────────────────────────────────────
  void addPixel(int x, int y) {
    if (_selectedClass == null) return;
    final vm = labelManager.currentLabelVM;
    if (vm is SegmentationLabelViewModel) {
      vm.addPixel(x, y, _selectedClass!); // 내부에서 updateLabel(save) 수행
    }
  }

  void removePixel(int x, int y) {
    final vm = labelManager.currentLabelVM;
    if (vm is SegmentationLabelViewModel) {
      vm.removePixel(x, y); // 내부에서 updateLabel(save) 수행
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 드래그 선택 박스 (UI 보조)
  // ───────────────────────────────────────────────────────────────────────────
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
}
