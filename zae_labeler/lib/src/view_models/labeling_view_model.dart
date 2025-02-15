// lib/src/view_models/labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';

class LabelingViewModel extends ChangeNotifier {
  // 멤버 변수 선언
  final Project project;
  final StorageHelperInterface storageHelper; // ✅ Dependency Injection 허용

  bool _isInitialized = false;
  final bool _memoryOptimized = true;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Set<String> selectedLabels = {};

  // Getter & Setter
  bool get isInitialized => _isInitialized;

  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  String get currentDataFileName => currentUnifiedData.fileName;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;
  File? get currentImageFile => _currentUnifiedData.file;

  List<LabelEntry> get labelEntries => project.labelEntries;

  // Factory 생성자
  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  // 인스턴스 생성
  LabelingViewModel({required this.project, required this.storageHelper});

  Future<void> initialize() async {
    if (project.labelEntries.isEmpty) {
      project.labelEntries = await project.loadLabelEntries();
    }

    // ✅ 데이터 로딩 최적화
    if (_memoryOptimized) {
      _unifiedDataList.clear();
      _currentUnifiedData = project.dataPaths.isNotEmpty ? await UnifiedData.fromDataPath(project.dataPaths.first) : UnifiedData.empty();
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath)));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }

    _isInitialized = true; // ✅ 초기화 완료
    notifyListeners();
  }

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= project.labelEntries.length || project.labelEntries.isEmpty) {
      return LabelEntry.empty(); // ✅ 빈 리스트인 경우 기본값 반환
    }
    return project.labelEntries[_currentIndex];
  }

  Future<void> loadCurrentData() async {
    // ✅ 이름 변경
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;

    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);

    notifyListeners();
  }

  Future<void> addOrUpdateLabel(String label, LabelingMode mode) async {
    final dataId = project.dataPaths[_currentIndex].fileName;

    // ✅ 기존 데이터 가져오기 (비동기 로드를 제거하고 즉시 참조)
    LabelEntry? existingEntry = project.labelEntries.firstWhere(
      (entry) => entry.dataFilename == dataId,
      orElse: () => LabelEntry.empty(),
    );

    if (existingEntry.dataFilename.isEmpty) {
      existingEntry = LabelEntry(
        dataFilename: dataId,
        dataPath: project.dataPaths[_currentIndex].filePath ?? '',
      );
      project.labelEntries.add(existingEntry);
    }

    // ✅ 선택한 Label 반영
    switch (mode) {
      case LabelingMode.singleClassification:
        existingEntry.singleClassification = SingleClassificationLabel(
          labeledAt: DateTime.now().toIso8601String(),
          label: label,
        );
        break;
      case LabelingMode.multiClassification:
        existingEntry.multiClassification ??= MultiClassificationLabel(
          labeledAt: DateTime.now().toIso8601String(),
          labels: [],
        );
        if (existingEntry.multiClassification!.labels.contains(label)) {
          existingEntry.multiClassification!.labels.remove(label);
        } else {
          existingEntry.multiClassification!.labels.add(label);
          existingEntry.multiClassification!.labeledAt = DateTime.now().toIso8601String();
        }
        break;
      case LabelingMode.segmentation:
        // TODO: Segmentation 라벨 추가 로직 필요
        break;
    }

    // ✅ 변경된 데이터를 즉시 `labelEntries`에 반영
    int index = project.labelEntries.indexWhere((entry) => entry.dataFilename == dataId);
    if (index != -1) {
      project.labelEntries[index] = existingEntry;
    } else {
      project.labelEntries.add(existingEntry);
    }

    notifyListeners(); // ✅ UI 즉시 업데이트

    // ✅ 저장소에 비동기 저장 (UI 갱신을 늦추지 않도록 함)
    await storageHelper.saveLabelEntry(project.id, existingEntry);
  }

  bool isLabelSelected(String label, LabelingMode mode) {
    LabelEntry entry = currentLabelEntry; // ✅ 최신 LabelEntry 가져오기

    switch (mode) {
      case LabelingMode.singleClassification:
        return entry.singleClassification?.label == label;
      case LabelingMode.multiClassification:
        if (entry.multiClassification == null) return false;
        return entry.multiClassification?.labels.contains(label) ?? false;
      default:
        return false;
    }
  }

  void toggleLabel(String label, LabelingMode mode) {
    if (isLabelSelected(label, mode)) {
      selectedLabels.remove(label);
    } else {
      selectedLabels.add(label);
    }
    notifyListeners();
  }

  Future<void> _move(int delta) async {
    int newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      notifyListeners();
      await loadCurrentData();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await storageHelper.downloadLabelsAsZip(project, project.labelEntries, []);
  }
}
