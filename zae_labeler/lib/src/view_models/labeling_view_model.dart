import 'dart:io';
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/storage_helper.dart';
import 'label_view_model.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;

  bool _isInitialized = false;
  final bool _memoryOptimized = true;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Set<String> selectedLabels = {};
  final Map<String, LabelViewModel> _labelCache = {}; // ✅ LabelViewModel 캐싱

  bool get isInitialized => _isInitialized;

  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  String get currentDataFileName => currentUnifiedData.fileName;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;
  File? get currentImageFile => _currentUnifiedData.file;

  // ✅ LabelViewModel을 활용한 현재 데이터 라벨 가져오기
  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  LabelingViewModel({required this.project, required this.storageHelper});

  Future<void> initialize() async {
    // ✅ 데이터 로딩 최적화
    if (_memoryOptimized) {
      _unifiedDataList.clear();
      _currentUnifiedData = project.dataPaths.isNotEmpty ? await UnifiedData.fromDataPath(project.dataPaths.first) : UnifiedData.empty();
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath)));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// ✅ 현재 파일의 `LabelViewModel`을 가져오거나 생성
  LabelViewModel getOrCreateLabelVM() {
    final dataFilename = currentUnifiedData.fileName;

    if (_labelCache.containsKey(dataFilename)) {
      return _labelCache[dataFilename]!;
    }

    final dataPath = project.dataPaths.firstWhere((dp) => dp.fileName == dataFilename).filePath ?? '';

    final newLabelVM = LabelViewModel(
        projectId: project.id, dataFilename: dataFilename, dataPath: dataPath, mode: project.mode, labelModel: LabelModelFactory.createNew(project.mode));

    _labelCache[dataFilename] = newLabelVM;
    return newLabelVM;
  }

  Future<void> loadCurrentData() async {
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;
    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
    notifyListeners();
  }

  /// ✅ Label 추가 또는 업데이트
  Future<void> addOrUpdateLabel(dynamic labelData) async {
    final labelVM = getOrCreateLabelVM();

    if (labelVM.labelModel.isMultiClass) {
      if (labelData is List<String>) {
        labelVM.updateLabel(labelData); // ✅ 다중 분류는 List<String> 필요
      } else if (labelData is String) {
        labelVM.updateLabel([labelData]); // ✅ String을 List<String>으로 변환하여 전달
      } else {
        throw ArgumentError("Expected a List<String> for MultiClassificationLabelModel, but got ${labelData.runtimeType}");
      }
    } else {
      if (labelData is String) {
        labelVM.updateLabel(labelData); // ✅ 단일 분류는 String 필요
      } else {
        throw ArgumentError("Expected a String for SingleClassificationLabelModel, but got ${labelData.runtimeType}");
      }
    }
    notifyListeners();
    await labelVM.saveLabel();
  }

  /// ✅ 현재 선택된 라벨인지 확인
  bool isLabelSelected(String label) {
    final labelVM = getOrCreateLabelVM();
    return labelVM.labelModel.label == label;
  }

  /// ✅ 라벨 선택/해제
  void toggleLabel(String label) {
    isLabelSelected(label) ? selectedLabels.remove(label) : selectedLabels.add(label);
    notifyListeners();
  }

  Future<void> _move(int delta) async {
    int newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      await loadCurrentData();
      notifyListeners();
    }
  }

  /// ✅ Label Export (ZIP 다운로드)
  Future<String> exportAllLabels() async {
    final allLabels = _labelCache.values.map((vm) => vm.labelModel).toList();
    return await storageHelper.exportAllLabels(project, allLabels, project.dataPaths);
  }
}

class SegmentationLabelingViewModel extends LabelingViewModel {
  int _gridSize = 32; // ✅ 기본 Grid 크기
  int get gridSize => _gridSize;

  Offset? _startDrag;
  Offset? _currentPointerPosition;
  Offset? get startDrag => _startDrag;
  Offset? get currentPointerPosition => _currentPointerPosition;

  List<List<int>> _labelGrid = List.generate(32, (_) => List.filled(32, 0));
  List<List<int>> get labelGrid => _labelGrid;

  SegmentationLabelingViewModel({required super.project, required super.storageHelper});

  /// ✅ Grid 크기 조절 (초기화 포함)
  void setGridSize(int newSize) {
    _gridSize = newSize;
    _labelGrid = List.generate(newSize, (_) => List.filled(newSize, 0)); // ✅ Grid 크기 변경 시 초기화
    notifyListeners();
  }

  /// ✅ Grid 내 픽셀들을 전체적으로 업데이트
  void updateSegmentationGrid(List<List<int>> labeledData) {
    if (labeledData.length == _gridSize && labeledData[0].length == _gridSize) {
      _labelGrid = labeledData;
      notifyListeners();
    }
  }

  /// ✅ 개별 픽셀 업데이트 (기존 메서드 유지)
  void updateSegmentationLabel(int x, int y, int label) {
    if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
      _labelGrid[y][x] = label;
      notifyListeners();
    }
  }

  /// ✅ Grid 초기화
  void clearLabels() {
    _labelGrid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    notifyListeners();
  }

  /// ✅ Bounding Box 선택 시작
  void startBoxSelection(Offset position) {
    _startDrag = position;
    notifyListeners();
  }

  /// ✅ Bounding Box 선택 업데이트
  void updateBoxSelection(Offset position) {
    _currentPointerPosition = position;
    notifyListeners();
  }

  /// ✅ Bounding Box 선택 완료
  void endBoxSelection() {
    _startDrag = null;
    _currentPointerPosition = null;
    notifyListeners();
  }
}
