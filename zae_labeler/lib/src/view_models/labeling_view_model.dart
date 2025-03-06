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
    final newLabelVM =
        LabelViewModel(projectId: project.id, dataFilename: dataFilename, dataPath: dataPath, mode: project.mode, labelModel: LabelModel.empty());

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
    labelVM.updateLabel(labelData);

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
