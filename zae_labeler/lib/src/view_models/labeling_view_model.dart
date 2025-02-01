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

  UnifiedData? _currentUnifiedData;
  UnifiedData? get currentUnifiedData => _currentUnifiedData;

  List<UnifiedData> _unifiedDataList = [];
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  List<LabelEntry> get labelEntries => project.labelEntries;

  String get currentDataFileName => labelEntries.isNotEmpty ? path.basename(labelEntries[_currentIndex].dataFilename) : "";

  List<double>? get currentSeriesData => _currentUnifiedData?.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData?.objectData;
  File? get currentImageFile => _currentUnifiedData?.file;

  LabelingViewModel({required this.project, required this.storageHelper});

  Future<void> initialize() async {
    if (project.labelEntries.isEmpty) {
      project.labelEntries = await project.loadLabelEntries();
    }

    _unifiedDataList = []; // ✅ 하나씩 로드하는 방식으로 변경

    // ✅ 첫 번째 데이터만 로드
    if (project.dataPaths.isNotEmpty) {
      _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths.first);
    }
    _isInitialized = true; // ✅ 초기화 완료
    notifyListeners();
  }

  // Future<void> loadAllData() async {
  //   try {
  //     if (memoryOptimized) {
  //       _unifiedDataList = [];
  //     } else {
  //       List<Future<UnifiedData>> loadingTasks = project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath)).toList();
  //       _unifiedDataList = await Future.wait(loadingTasks);
  //     }

  //     print("✅ loadAllData 완료: unifiedDataList 길이 = ${_unifiedDataList.length}");
  //   } catch (e) {
  //     print("❌ loadAllData에서 오류 발생: $e");
  //   }
  // }

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= project.labelEntries.length || project.labelEntries.isEmpty) {
      return LabelEntry.empty(); // ✅ 빈 리스트인 경우 기본값 반환
    }
    return project.labelEntries[_currentIndex];
  }

  Future<void> loadCurrentData() async {
    // ✅ 이름 변경
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;

    if (!memoryOptimized) {
      // ✅ 현재, 이전, 다음 데이터를 로드
      List<int> indicesToLoad = [
        if (_currentIndex > 0) _currentIndex - 1, // 이전
        _currentIndex, // 현재
        if (_currentIndex < project.dataPaths.length - 1) _currentIndex + 1, // 다음
      ];

      _unifiedDataList = await Future.wait(indicesToLoad.map((index) => UnifiedData.fromDataPath(project.dataPaths[index])));
      _currentUnifiedData = _unifiedDataList.firstWhere(
        (data) => data.file == project.dataPaths[_currentIndex].filePath,
        orElse: () => UnifiedData.empty(),
      );
    } else {
      // ✅ 메모리 최적화 모드에서는 하나씩 로드
      _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
    }

    notifyListeners();
  }

  Future<void> addOrUpdateLabel(String label, String mode) async {
    final dataId = project.dataPaths[_currentIndex].fileName;

    // ✅ 특정 `dataPath`만 불러오기
    LabelEntry existingEntry = await storageHelper.loadLabelEntry(dataId);

    switch (mode) {
      case 'single_classification':
        existingEntry.singleClassification = SingleClassificationLabel(
          labeledAt: DateTime.now().toIso8601String(),
          label: label,
        );
        break;
      case 'multi_classification':
        existingEntry.multiClassification ??= MultiClassificationLabel(labeledAt: DateTime.now().toIso8601String(), labels: []);
        if (!existingEntry.multiClassification!.labels.contains(label)) {
          existingEntry.multiClassification!.labels.add(label);
          existingEntry.multiClassification!.labeledAt = DateTime.now().toIso8601String();
        }
        break;
      case 'segmentation':
        // TODO: Segmentation 라벨 추가 로직 필요
        break;
      default:
        break;
    }

    // ✅ 특정 데이터만 저장
    await storageHelper.saveLabelEntry(existingEntry);

    // ✅ `labelEntries` 전체를 다시 로드하는 대신, 변경된 항목만 업데이트
    final index = project.labelEntries.indexWhere((entry) => entry.dataPath == dataId);
    if (index != -1) {
      project.labelEntries[index] = existingEntry;
    } else {
      project.labelEntries.add(existingEntry);
    }

    notifyListeners();
  }

  bool isLabelSelected(String label, String mode) {
    LabelEntry entry = currentLabelEntry;
    switch (mode) {
      case 'single_classification':
        return entry.singleClassification?.label == label;
      case 'multi_classification':
        return entry.multiClassification?.labels.contains(label) ?? false;
      default:
        return false;
    }
  }

  Future<void> moveNext() async {
    if (_currentIndex < project.dataPaths.length - 1) {
      _currentIndex++;
      await loadCurrentData();
      notifyListeners();
    }
  }

  Future<void> movePrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await loadCurrentData();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await storageHelper.downloadLabelsAsZip(project, project.labelEntries, []);
  }
}
