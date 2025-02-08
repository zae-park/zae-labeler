// lib/src/view_models/labeling_view_model.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper; // ✅ Dependency Injection 허용

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized; // ✅ 추가

  // ✅ 메모리 최적화 여부 (기본값: true).
  // false로 설정하면 모든 UnifiedData를 로드하고 메모리에 유지함.
  // true로 설정하면 빈 UnifiedDataList를 생성 후 하나씩 로드함.
  bool memoryOptimized = true;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  UnifiedData _currentUnifiedData = UnifiedData.empty();
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  List<UnifiedData> _unifiedDataList = [];
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  List<LabelEntry> get labelEntries => project.labelEntries;

  String get currentDataFileName => currentUnifiedData.fileName;

  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;
  File? get currentImageFile => _currentUnifiedData.file;

  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  LabelingViewModel({required this.project, required this.storageHelper});

  Future<void> initialize() async {
    if (project.labelEntries.isEmpty) {
      project.labelEntries = await project.loadLabelEntries();
    }

    if (memoryOptimized) {
      _unifiedDataList = [];
      if (project.dataPaths.isNotEmpty) {
        _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths.first);
      }
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath)));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : null;
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

    // ✅ 특정 `dataPath`만 불러오기
    LabelEntry existingEntry = await storageHelper.loadLabelEntry(dataId);

    switch (mode) {
      case LabelingMode.singleClassification:
        existingEntry.singleClassification = SingleClassificationLabel(
          labeledAt: DateTime.now().toIso8601String(),
          label: label,
        );
        break;
      case LabelingMode.multiClassification:
        existingEntry.multiClassification ??= MultiClassificationLabel(labeledAt: DateTime.now().toIso8601String(), labels: []);
        if (!existingEntry.multiClassification!.labels.contains(label)) {
          existingEntry.multiClassification!.labels.add(label);
          existingEntry.multiClassification!.labeledAt = DateTime.now().toIso8601String();
        }
        break;
      case LabelingMode.segmentation:
        // TODO: Segmentation 라벨 추가 로직 필요
        break;
      default:
        break;
    }

    // ✅ 특정 데이터만 저장
    await storageHelper.saveLabelEntry(existingEntry);

    // ✅ `labelEntries` 전체를 다시 로드하는 대신, 변경된 항목만 업데이트
    final index = project.labelEntries.indexWhere((entry) => entry.dataPath == dataId);
    project.labelEntries = List.from(project.labelEntries)..[index] = existingEntry;
    notifyListeners();
  }

  bool isLabelSelected(String label, LabelingMode mode) {
    LabelEntry entry = currentLabelEntry;
    switch (mode) {
      case LabelingMode.singleClassification:
        return entry.singleClassification?.label == label;
      case LabelingMode.multiClassification:
        return entry.multiClassification?.labels.contains(label) ?? false;
      default:
        return false;
    }
  }

  Future<void> _move(int delta) async {
    int newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      await loadCurrentData();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await storageHelper.downloadLabelsAsZip(project, project.labelEntries, []);
  }
}
