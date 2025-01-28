// lib/src/view_models/labeling_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/storage_helper.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final List<LabelEntry> _labelEntries = [];
  int _currentIndex = 0;

  final List<UnifiedData> _unifiedDataList = [];
  UnifiedData? _currentUnifiedData; // 현재 데이터 상태
  UnifiedData? get currentUnifiedData => _currentUnifiedData;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LabelingViewModel({required this.project});

  List<LabelEntry> get labelEntries => _labelEntries;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  int get currentIndex => _currentIndex;
  String get currentDataFileName => _labelEntries.isNotEmpty ? path.basename(_labelEntries[_currentIndex].dataFilename) : "";

  // 현재 데이터의 시계열, 오브젝트, 이미지 데이터 반환
  List<double>? get currentSeriesData => _currentUnifiedData?.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData?.objectData;
  File? get currentImageFile => _currentUnifiedData?.file;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = false; // 초기화 시작
    try {
      // 프로젝트를 통해 라벨 엔트리 로드
      _labelEntries.clear();
      final loadedLabelEntries = await StorageHelper().loadLabelEntries();
      _labelEntries.addAll(loadedLabelEntries);
      _unifiedDataList.clear();
      _unifiedDataList.addAll(await Future.wait(project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath))));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : null;
      // 초기 데이터 로드
      if (_labelEntries.isNotEmpty) {
        await updateLabelState();
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= _labelEntries.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }
    return _labelEntries[_currentIndex];
  }

  Future<void> updateLabelState() async {
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;

    final currentEntry = _labelEntries[_currentIndex];
    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
    notifyListeners();
  }

  void addOrUpdateLabel(int dataIndex, String label, String mode) {
    if (dataIndex < 0 || dataIndex >= _labelEntries.length) return;

    final dataId = project.dataPaths[dataIndex].fileName;
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

      // Save updated project
      StorageHelper.instance.saveProjects([project]);
      notifyListeners();
    }
  }

  bool isLabelSelected(String label, String mode) {
    LabelEntry entry = currentLabelEntry;
    switch (mode) {
      case 'single_classification':
        return entry.singleClassification?.label == label;
      case 'multi_classification':
        return entry.multiClassification?.labels.contains(label) ?? false;
      // Segmentation mode는 UI에서 별도로 관리 필요
      default:
        return false;
    }
  }

  void moveNext() {
    if (_currentIndex < project.dataPaths.length - 1) {
      _currentIndex++;
      updateLabelState();
      notifyListeners();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      updateLabelState();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await StorageHelper().downloadLabelsAsZip(project, _labelEntries, []);
  }
}
