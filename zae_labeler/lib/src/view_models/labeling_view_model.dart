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
  List<FileData> _fileDataList = [];
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
  String get currentDataFileName => _fileDataList.isNotEmpty ? path.basename(_fileDataList[_currentIndex].name) : "";

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
                seriesExtensions.contains(path.extension(file.path.split(':')[0]).toLowerCase()) ||
                objectExtensions.contains(path.extension(file.path.split(':')[0]).toLowerCase()) ||
                imageExtensions.contains(path.extension(file.path.split(':')[0]).toLowerCase()))
            .toList();
        _fileDataList = project.dataPaths!.map((filePath) {
          final fileParts = filePath.split(':'); // 'name.ext:base64content' 구조
          final fileNameParts = fileParts[0].split('.'); // 'name.ext'에서 분리

          return FileData(
            name: fileNameParts[0], // 파일 이름 (확장자 제외)
            type: ".${fileNameParts[1]}", // 파일 확장자
            content: fileParts[1], // Base64로 인코딩된 콘텐츠
          );
        }).toList();
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

  Future<void> loadCurrentFileData() async {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return;
    }

    if (kIsWeb) {
      final fileData = _fileDataList[_currentIndex];

      if (seriesExtensions.contains(fileData.type)) {
        final seriesData = await _loadSeriesDataFromString(fileData.content);
        _currentUnifiedData = UnifiedData(seriesData: seriesData, fileType: FileType.series);
      } else if (objectExtensions.contains(fileData.type)) {
        final objectData = await _loadObjectDataFromString(fileData.content);
        print(objectData);
        _currentUnifiedData = UnifiedData(objectData: objectData, fileType: FileType.object);
      } else if (imageExtensions.contains(fileData.type)) {
        _currentUnifiedData = UnifiedData(fileType: FileType.image);
      } else {
        _currentUnifiedData = UnifiedData(fileType: FileType.unsupported);
      }
    } else {
      // native env
      final fileData = _dataFiles[_currentIndex];
      final extension = path.extension(fileData.path).toLowerCase();
      if (seriesExtensions.contains(extension)) {
        final seriesData = await _loadSeriesData(fileData);
        _currentUnifiedData = UnifiedData(file: fileData, seriesData: seriesData, fileType: FileType.series);
      } else if (objectExtensions.contains(extension)) {
        final objectData = await _loadObjectData(fileData);
        _currentUnifiedData = UnifiedData(file: fileData, objectData: objectData, fileType: FileType.object);
      } else if (imageExtensions.contains(extension)) {
        _currentUnifiedData = UnifiedData(file: fileData, fileType: FileType.image);
      } else {
        _currentUnifiedData = UnifiedData(file: fileData, fileType: FileType.unsupported);
      }
    }
  }

  Future<List<double>> _loadSeriesData(File file) async {
    final lines = await file.readAsLines();
    return lines.expand((line) => line.split(',')).map((part) => double.tryParse(part.trim()) ?? 0.0).toList();
  }

  Future<List<double>> _loadSeriesDataFromString(String base64EncodedData) async {
    // Step 1: Base64 디코딩
    final decodedData = utf8.decode(base64Decode(base64EncodedData));

    // Step 2: 문자열 데이터를 줄바꿈('\n')으로 나누기
    final lines = decodedData.split('\n');

    // Step 3: ','를 기준으로 나누고, 숫자로 변환
    return lines
        .expand((line) => line.split(',')) // 각 줄을 ','로 나누기
        .map((part) => double.tryParse(part.trim()) ?? 0.0) // 숫자로 변환, 실패 시 0.0 반환
        .toList();
  }

  Future<Map<String, dynamic>> _loadObjectData(File file) async {
    final content = await file.readAsString();
    return jsonDecode(content);
  }

  Future<Map<String, dynamic>> _loadObjectDataFromString(String encodedData) async {
    try {
      // Step 1: Base64 디코딩
      if (encodedData.isEmpty) {
        throw const FormatException('Input data is empty.');
      }
      final decodedData = utf8.decode(base64Decode(encodedData));

      // Step 2: JSON 디코딩
      final jsonData = jsonDecode(decodedData);

      // Step 3: 결과가 Map<String, dynamic>인지 확인
      if (jsonData is Map<String, dynamic>) {
        return jsonData;
      } else {
        throw const FormatException('Decoded data is not a valid JSON object.');
      }
    } catch (e) {
      // 예외를 명확히 하여 사용자에게 메시지를 제공
      throw FormatException('Failed to parse JSON data. Error: $e');
    }
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
    return await StorageHelper().downloadLabelsAsZip(project, _labelEntries, _dataFiles);
  }
}
