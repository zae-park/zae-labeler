// lib/src/view_models/labeling_view_model.dart
import 'dart:convert';
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
    if (_currentIndex < 0 || _currentIndex >= project.labelEntries.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }
    return project.labelEntries[_currentIndex];
  }

  Future<void> updateLabelState() async {
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;
    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
    notifyListeners();
  }

  void addOrUpdateLabel(String label, String mode) {
    final dataId = project.dataPaths[_currentIndex].fileName;
    final existingEntryIndex = project.labelEntries.indexWhere((entry) => entry.dataPath == dataId);

    if (existingEntryIndex != -1) {
      LabelEntry entry = project.labelEntries[existingEntryIndex];
      switch (mode) {
        case 'single_classification':
          entry.singleClassification = SingleClassificationLabel(
            labeledAt: DateTime.now().toIso8601String(),
            label: label,
          );
          break;
        case 'multi_classification':
          if (entry.multiClassification == null) {
            entry.multiClassification = MultiClassificationLabel(
              labeledAt: DateTime.now().toIso8601String(),
              labels: [label],
            );
          } else {
            if (!entry.multiClassification!.labels.contains(label)) {
              entry.multiClassification!.labels.add(label);
              entry.multiClassification!.labeledAt = DateTime.now().toIso8601String();
            }
          }
          break;
        case 'segmentation':
          // Segmentation 라벨 추가 로직 필요
          break;
        default:
          break;
      }
    } else {
      project.labelEntries.add(LabelEntry(
        dataFilename: dataId,
        dataPath: dataId,
        singleClassification: SingleClassificationLabel(
          labeledAt: DateTime.now().toIso8601String(),
          label: label,
        ),
      ));
    }

    // Save updated project
    storageHelper.saveProjects([project]); // ✅ Mock 가능하도록 수정
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

  void moveNext() async {
    if (_currentIndex < project.dataPaths.length - 1) {
      _currentIndex++;
      await updateLabelState();
      notifyListeners();
    }
  }

  void movePrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await updateLabelState();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await storageHelper.downloadLabelsAsZip(project, project.labelEntries, []);
  }
}
