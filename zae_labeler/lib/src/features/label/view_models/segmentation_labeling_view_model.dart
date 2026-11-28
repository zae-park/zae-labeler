// lib/src/features/label/view_models/segmentation_labeling_view_model.dart
import 'package:zae_labeler/src/core/models/label/label_model.dart';

import 'labeling_view_model.dart';

/// 세그멘테이션 라벨링 VM (그리드 픽셀 마스크).
///
/// - 라벨의 단일 소스는 현재 데이터의 [SegmentationData]이며, 그리드([labelGrid])는 그로부터 파생됩니다.
/// - 픽셀은 하나의 클래스에만 속합니다(칠하면 다른 클래스에서 제거).
/// - 드래그 한 번(stroke)은 메모리에만 쌓이고, [endStroke]에서 **한 번** 저장합니다.
class SegmentationLabelingViewModel extends LabelingViewModel {
  SegmentationLabelingViewModel({required super.project, required super.storageHelper, required super.labelUseCases, super.dataManager, int gridSize = 32})
    : _gridSize = gridSize;

  /// 빈 셀
  static const int emptyCell = 0;

  /// 프로젝트 클래스 목록에 없는 클래스로 칠해진 셀(보존만 하고 회색으로 표시)
  static const int unknownClassCell = -1;

  final int _gridSize;
  int get gridSize => _gridSize;

  String? _selectedClass;
  String? get selectedClass => _selectedClass;

  bool _isErasing = false;
  bool get isErasing => _isErasing;

  final Set<(int, int)> _stroke = {};

  /// 진행 중인(아직 저장되지 않은) stroke의 셀들.
  Set<(int, int)> get pendingStroke => Set.unmodifiable(_stroke);

  @override
  Future<void> postInitialize() async {
    if (_selectedClass == null && project.classes.isNotEmpty) {
      _selectedClass = project.classes.first;
    }
  }

  @override
  Future<void> postMove() async => _stroke.clear();

  // ───────────────────────────────────────────────────────────────────────────
  // 도구 선택
  // ───────────────────────────────────────────────────────────────────────────

  void setSelectedClass(String classLabel) {
    _selectedClass = classLabel;
    _isErasing = false;
    notify();
  }

  void setErasing(bool value) {
    _isErasing = value;
    notify();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 라벨 ↔ 그리드
  // ───────────────────────────────────────────────────────────────────────────

  SegmentationData get currentSegmentation {
    final v = currentLabel?.label;
    return v is SegmentationData ? v : SegmentationData.empty;
  }

  /// 셀 값: [emptyCell], 클래스 인덱스+1, 또는 [unknownClassCell].
  List<List<int>> get labelGrid {
    final grid = List.generate(_gridSize, (_) => List.filled(_gridSize, emptyCell));
    for (final segment in currentSegmentation.segments.values) {
      final idx = project.classes.indexOf(segment.classLabel);
      final value = idx < 0 ? unknownClassCell : idx + 1;
      for (final (x, y) in segment.indices) {
        if (_inBounds(x, y)) grid[y][x] = value;
      }
    }
    return grid;
  }

  bool _inBounds(int x, int y) => x >= 0 && y >= 0 && x < _gridSize && y < _gridSize;

  // ───────────────────────────────────────────────────────────────────────────
  // Stroke 편집
  // ───────────────────────────────────────────────────────────────────────────

  void beginStroke() => _stroke.clear();

  /// 드래그 중 셀을 stroke에 추가합니다(저장하지 않음).
  void paintCell(int x, int y) {
    if (!_inBounds(x, y)) return;
    if (!_isErasing && _selectedClass == null) return;
    if (_stroke.add((x, y))) notify();
  }

  /// stroke를 라벨에 반영하고 한 번 저장합니다.
  Future<void> endStroke() async {
    if (_stroke.isEmpty) return;
    final cells = Set<(int, int)>.from(_stroke);
    _stroke.clear();

    final cleared = currentSegmentation.removePixels(cells);
    final next = _isErasing ? cleared : cleared.addPixels(cells, _selectedClass!);
    await applyInput(next);
  }

  /// 현재 데이터의 마스크를 모두 지웁니다.
  Future<void> clearLabels() async {
    _stroke.clear();
    await applyInput(SegmentationData.empty);
  }
}
