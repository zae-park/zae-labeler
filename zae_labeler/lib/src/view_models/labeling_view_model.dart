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

  UnifiedData? _currentUnifiedData; // 현재 데이터 상태
  UnifiedData? get currentUnifiedData => _currentUnifiedData;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LabelingViewModel({required this.project});

  List<LabelEntry> get labelEntries => _labelEntries;
  int get currentIndex => _currentIndex;
  String get currentDataFileName => _labelEntries.isNotEmpty ? path.basename(_labelEntries[_currentIndex].dataFilename) : "";

  // 현재 데이터의 시계열, 오브젝트, 이미지 데이터 반환
  List<double>? get currentSeriesData => _currentUnifiedData?.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData?.objectData;
  File? get currentImageFile => _currentUnifiedData?.file;

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= _labelEntries.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }
    return _labelEntries[_currentIndex];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 프로젝트를 통해 라벨 엔트리 로드
      _labelEntries.clear();
      _labelEntries.addAll(await StorageHelper().loadLabelEntries());
      _isInitialized = true;

      // 초기 데이터 로드
      if (_labelEntries.isNotEmpty) {
        await loadCurrentFileData();
      }

      notifyListeners();
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  Future<void> loadCurrentFileData() async {
    if (_currentIndex < 0 || _currentIndex >= _labelEntries.length) return;

    final currentEntry = _labelEntries[_currentIndex];
    _currentUnifiedData = await _loadDataFromEntry(currentEntry);
    notifyListeners();
  }

  Future<UnifiedData> _loadDataFromEntry(LabelEntry entry) async {
    final dataPath = entry.dataPath;
    final fileName = entry.dataFilename;

    if (fileName.endsWith('.csv')) {
      final seriesData = await _loadSeriesData(dataPath);
      return UnifiedData(seriesData: seriesData, fileType: FileType.series);
    } else if (fileName.endsWith('.json')) {
      final objectData = await _loadObjectData(dataPath);
      return UnifiedData(objectData: objectData, fileType: FileType.object);
    } else if (['.png', '.jpg', '.jpeg'].any((ext) => fileName.endsWith(ext))) {
      final file = File(dataPath);
      return UnifiedData(file: file, fileType: FileType.image);
    }

    return UnifiedData(fileType: FileType.unsupported);
  }

  Future<List<double>> _loadSeriesData(String path) async {
    final file = File(path);
    final lines = await file.readAsLines();
    return lines.expand((line) => line.split(',')).map((part) => double.tryParse(part.trim()) ?? 0.0).toList();
  }

  Future<Map<String, dynamic>> _loadObjectData(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    return jsonDecode(content);
  }

  void addOrUpdateLabel(int dataIndex, String label, String mode) {
    if (dataIndex < 0 || dataIndex >= _labelEntries.length) return;
    final dataId = _labelEntries[dataIndex].dataPath;

    final existingEntryIndex = _labelEntries.indexWhere((entry) => entry.dataPath == dataId);

    if (existingEntryIndex != -1) {
      LabelEntry entry = _labelEntries[existingEntryIndex];
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
      LabelEntry newEntry = LabelEntry(dataFilename: path.basename(dataId), dataPath: dataId);
      switch (mode) {
        case 'single_classification':
          newEntry.singleClassification = SingleClassificationLabel(labeledAt: DateTime.now().toIso8601String(), label: label);
          break;
        case 'multi_classification':
          newEntry.multiClassification = MultiClassificationLabel(labeledAt: DateTime.now().toIso8601String(), labels: [label]);
          break;
        case 'segmentation':
          // Segmentation 라벨 추가 로직 필요
          break;
        default:
          break;
      }
      _labelEntries.add(newEntry);
    }

    StorageHelper().saveLabelEntries(_labelEntries);
    notifyListeners();
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
    if (_currentIndex < _labelEntries.length - 1) {
      _currentIndex++;
      loadCurrentFileData();
      notifyListeners();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      loadCurrentFileData();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await StorageHelper().downloadLabelsAsZip(project, _labelEntries, []);
  }
}
