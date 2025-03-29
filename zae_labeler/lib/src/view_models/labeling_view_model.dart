// lib/src/view_models/labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/storage_helper.dart';
import 'label_view_model.dart';

/// ✅ 라벨링 전체 흐름을 조율하는 뷰모델
///
/// `LabelingViewModel`은 프로젝트의 데이터 단위로 라벨링을 수행하고,
/// 각 데이터에 대응되는 `LabelViewModel`을 생성 및 관리합니다.
/// ///
/// - 데이터 이동 (`moveNext`, `movePrevious`)을 통해 현재 데이터를 갱신하고,
/// - 해당 데이터의 라벨을 생성, 불러오기, 업데이트, 저장까지 담당합니다.
/// - 실제 라벨의 타입에 따라 분류/세그멘테이션 등 다양한 모델을 다룰 수 있습니다.
///
/// ⚠️ `LabelViewModel`과의 차이점:
/// - `LabelViewModel`은 **개별 데이터 단위의 라벨**만을 관리합니다.
/// - `LabelingViewModel`은 **프로젝트 단위**에서 데이터 전체의 흐름과 라벨 캐싱, 전환, 저장을 담당합니다.
class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;

  bool _isInitialized = false;
  final bool _memoryOptimized = true;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Set<String> selectedLabels = {}; // ✅ UI 상태 관리용
  final Map<String, LabelViewModel> _labelCache = {}; // ✅ LabelViewModel 캐싱

  bool get isInitialized => _isInitialized;

  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  String get currentDataFileName => currentUnifiedData.fileName;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;
  File? get currentImageFile => _currentUnifiedData.file;

  /// ✅ 현재 데이터에 대응되는 라벨 뷰모델
  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  /// ✅ 생성자 - 프로젝트 및 저장 헬퍼 주입
  LabelingViewModel({required this.project, required this.storageHelper});

  /// ✅ 생성자 - 프로젝트 및 저장 헬퍼 주입
  Future<void> initialize() async {
    if (_memoryOptimized) {
      _unifiedDataList.clear();
      _currentUnifiedData = project.dataPaths.isNotEmpty ? await UnifiedData.fromDataPath(project.dataPaths.first) : UnifiedData.empty();
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath)));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }
    await getOrCreateLabelVM().loadLabel();

    _isInitialized = true;
    notifyListeners();
  }

  /// ✅ 현재 데이터에 해당하는 LabelViewModel을 생성 or 재사용
  LabelViewModel getOrCreateLabelVM() {
    final id = currentUnifiedData.dataId;

    if (_labelCache.containsKey(id)) return _labelCache[id]!;

    final newLabelVM = LabelViewModel(
      projectId: project.id,
      dataId: id, // ✅ 캐시 키로 사용
      dataFilename: currentUnifiedData.fileName,
      dataPath: currentUnifiedData.file?.path ?? '',
      mode: project.mode,
      labelModel: LabelModelFactory.createNew(project.mode),
    );

    _labelCache[id] = newLabelVM;
    return newLabelVM;
  }

  /// ✅ 현재 인덱스 위치의 데이터를 로드하고 라벨 동기화
  Future<void> loadCurrentData() async {
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;
    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);

    final id = _currentUnifiedData.dataId;

    if (_labelCache.containsKey(id)) {
      final loadedLabel = await storageHelper.loadLabelData(project.id, id, _currentUnifiedData.file?.path ?? '', project.mode);
      _labelCache[id]!.labelModel = loadedLabel;
    } else {
      final labelVM = LabelViewModel(
        projectId: project.id,
        dataId: id,
        dataFilename: _currentUnifiedData.fileName,
        dataPath: _currentUnifiedData.file?.path ?? '',
        mode: project.mode,
        labelModel: LabelModelFactory.createNew(project.mode),
      );
      await labelVM.loadLabel(); // ✅ 여기에 저장된 타입에 맞게 불러옴
      _labelCache[id] = labelVM;
    }

    notifyListeners();
  }

  /// ✅ 현재 데이터에 대한 라벨을 업데이트 및 저장
  ///
  /// `labelData`는 모델 내부에서 타입에 따라 처리됩니다.
  Future<void> addOrUpdateLabel(dynamic labelData) async {
    final labelVM = getOrCreateLabelVM();
    labelVM.updateLabel(labelData);
    // if (labelVM.labelModel.isMultiClass) {
    //   if (labelData is List<String>) {
    //     labelVM.updateLabel(labelData); // ✅ 다중 분류는 List<String> 필요
    //   } else if (labelData is String) {
    //     labelVM.updateLabel([labelData]); // ✅ String을 List<String>으로 변환하여 전달
    //   } else {
    //     throw ArgumentError("Expected a List<String> for MultiClassificationLabelModel, but got ${labelData.runtimeType}");
    //   }
    // } else {
    //   if (labelData is String) {
    //     labelVM.updateLabel(labelData); // ✅ 단일 분류는 String 필요
    //   } else {
    //     throw ArgumentError("Expected a String for SingleClassificationLabelModel, but got ${labelData.runtimeType}");
    //   }
    // }
    await labelVM.saveLabel();
    notifyListeners();
  }

  /// ✅ 해당 라벨이 현재 라벨과 일치하는지 확인 (단일 선택 UI용)
  bool isLabelSelected(String label) {
    final labelVM = getOrCreateLabelVM();
    return labelVM.labelModel.label == label;
  }

  /// ✅ UI에서 라벨 선택 여부를 토글 (단순 시각 상태용, 저장은 아님)
  ///
  /// ❗ 내부 라벨 모델과 직접 연결되어 있지 않음.
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
