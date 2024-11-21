// lib/src/view_models/labeling_view_model.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/storage_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final List<LabelEntry> _labelEntries = [];
  int _currentIndex = 0;
  List<File> _dataFiles = [];
  final List<double> _currentSeriesData = [];
  Map<String, dynamic>? _currentObjectData;
  File? _currentImageFile;

  bool _isInitialized = false; // 초기화 상태를 관리
  bool get isInitialized => _isInitialized;

  UnifiedData? _currentUnifiedData;
  UnifiedData? get currentData => _currentUnifiedData;

  LabelingViewModel({required this.project}) {
    _initialize();
  }

  List<LabelEntry> get labelEntries => _labelEntries;
  int get currentIndex => _currentIndex;
  List<File> get dataFiles => _dataFiles;
  List<double> get currentSeriesData => _currentSeriesData;
  Map<String, dynamic>? get currentObjectData => _currentObjectData;
  File? get currentImageFile => _currentImageFile;
  String get currentFileName => _dataFiles.isNotEmpty ? path.basename(_dataFiles[_currentIndex].path) : '';

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }

    final dataId = _dataFiles[_currentIndex].path;
    final entry = _labelEntries.firstWhere(
      (labelEntry) => labelEntry.dataPath == dataId,
      orElse: () => LabelEntry(
        dataFilename: path.basename(dataId),
        dataPath: dataId,
      ),
    );
    return entry;
  }

  final List<String> seriesExtensions = ['.csv'];
  final List<String> objectExtensions = ['.json'];
  final List<String> imageExtensions = ['.png', '.jpg', '.jpeg'];

  Future<void> _initialize() async {
    if (_isInitialized) return; // 이미 초기화가 완료되었으면 중단
    _isInitialized = false; // 초기화 시작
    await _loadLabels();
    await _loadDataFiles();
    await loadCurrentData();
    _isInitialized = true; // 초기화 완료
    notifyListeners(); // UI에 초기화 완료 알림
  }

  Future<void> _loadLabels() async {
    _labelEntries.addAll(await StorageHelper().loadLabelEntries());
    notifyListeners();
  }

  Future<void> _loadDataFiles() async {
    if (kIsWeb) {
      // Web 환경: 개별 파일 경로를 처리
      if (project.dataPaths != null) {
        _dataFiles = project.dataPaths!
            .map((filePath) => File(filePath))
            .where((file) =>
                seriesExtensions.contains(path.extension(file.path).toLowerCase()) ||
                objectExtensions.contains(path.extension(file.path).toLowerCase()) ||
                imageExtensions.contains(path.extension(file.path).toLowerCase()))
            .toList();
      }
    } else {
      // Native 환경: 디렉토리 내 파일을 탐색
      final directory = Directory(project.dataDirectory!);
      if (directory.existsSync()) {
        _dataFiles = directory
            .listSync()
            .where((file) =>
                file is File &&
                (seriesExtensions.contains(path.extension(file.path).toLowerCase()) ||
                    objectExtensions.contains(path.extension(file.path).toLowerCase()) ||
                    imageExtensions.contains(path.extension(file.path).toLowerCase())))
            .cast<File>()
            .toList();
      }
    }
  }

  Future<void> loadCurrentData() async {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return;
    }

    final file = _dataFiles[_currentIndex];
    final extension = path.extension(file.path).toLowerCase();

    if (seriesExtensions.contains(extension)) {
      final seriesData = await _loadSeriesData(file);
      _currentUnifiedData = UnifiedData(file: file, seriesData: seriesData, fileType: FileType.series);
    } else if (objectExtensions.contains(extension)) {
      final objectData = await _loadObjectData(file);
      _currentUnifiedData = UnifiedData(file: file, objectData: objectData, fileType: FileType.object);
    } else if (imageExtensions.contains(extension)) {
      _currentUnifiedData = UnifiedData(file: file, fileType: FileType.image);
    } else {
      _currentUnifiedData = UnifiedData(file: file, fileType: FileType.unsupported);
    }

    // notifyListeners();
  }

  Future<List<double>> _loadSeriesData(File file) async {
    final lines = await file.readAsLines();
    return lines.expand((line) => line.split(',')).map((part) => double.tryParse(part.trim()) ?? 0.0).toList();
  }

  Future<Map<String, dynamic>> _loadObjectData(File file) async {
    final content = await file.readAsString();
    return jsonDecode(content);
  }

  void addOrUpdateLabel(int dataIndex, String label, String mode) {
    if (dataIndex < 0 || dataIndex >= _dataFiles.length) return;
    final dataId = _dataFiles[dataIndex].path;

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
      LabelEntry newEntry = LabelEntry(
        dataFilename: path.basename(dataId),
        dataPath: dataId,
      );
      switch (mode) {
        case 'single_classification':
          newEntry.singleClassification = SingleClassificationLabel(
            labeledAt: DateTime.now().toIso8601String(),
            label: label,
          );
          break;
        case 'multi_classification':
          newEntry.multiClassification = MultiClassificationLabel(
            labeledAt: DateTime.now().toIso8601String(),
            labels: [label],
          );
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

  // 현재 라벨이 선택되었는지 확인
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
    if (_currentIndex < _dataFiles.length - 1) {
      _currentIndex++;
      loadCurrentData();
      notifyListeners();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      loadCurrentData();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await StorageHelper().downloadLabelsAsZip(project, _labelEntries, _dataFiles);
  }
}
