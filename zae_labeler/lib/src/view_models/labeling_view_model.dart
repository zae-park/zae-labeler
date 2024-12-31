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

  final List<FileData> _fileDataList = [];
  final List<double> _currentSeriesData = [];
  Map<String, dynamic>? _currentObjectData;
  File? _currentImageFile;

  bool _isInitialized = false; // 초기화 상태를 관리
  bool get isInitialized => _isInitialized;

  UnifiedData? _currentUnifiedData;
  UnifiedData? get currentData => _currentUnifiedData;
  FileData? _currentFileData;
  FileData? get currentFData => _currentFileData;

  LabelingViewModel({required this.project}) {
    _initialize();
  }

  List<LabelEntry> get labelEntries => _labelEntries;
  int get currentIndex => _currentIndex;
  List<FileData> get fileDataList => _fileDataList;
  List<double> get currentSeriesData => _currentSeriesData;
  Map<String, dynamic>? get currentObjectData => _currentObjectData;
  File? get currentImageFile => _currentImageFile;
  String get currentDataFileName => _fileDataList.isNotEmpty ? path.basename(_fileDataList[_currentIndex].name) : "";

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= _fileDataList.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }

    final dataId = _fileDataList[_currentIndex].name;
    final entry = _labelEntries.firstWhere(
      (labelEntry) => labelEntry.dataPath == dataId,
      orElse: () => LabelEntry(dataFilename: path.basename(dataId), dataPath: dataId),
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
    _fileDataList.clear();

    if (kIsWeb) {
      // Web 환경: 데이터 경로 처리
      if (project.dataPaths != null) {
        for (var filePath in project.dataPaths!) {
          final fileData = _parseWebFileData(filePath);
          if (_isValidFileType(fileData.type)) {
            _fileDataList.add(fileData);
          }
        }
      }
    } else {
      // Native 환경: 디렉토리 내 파일 탐색
      final directory = Directory(project.dataDirectory!);
      if (directory.existsSync()) {
        final files = directory.listSync().whereType<File>();
        for (var file in files) {
          final fileData = _parseNativeFileData(file);
          if (_isValidFileType(fileData.type)) {
            _fileDataList.add(fileData);
          }
        }
      }
    }
    notifyListeners();
  }

// 파일 유형 검증
  bool _isValidFileType(String fileType) {
    return seriesExtensions.contains(fileType.toLowerCase()) ||
        objectExtensions.contains(fileType.toLowerCase()) ||
        imageExtensions.contains(fileType.toLowerCase());
  }

// Web 환경 파일 파싱
  FileData _parseWebFileData(String filePath) {
    final fileParts = filePath.split(':'); // 'name.ext:base64content'
    final fileNameParts = fileParts[0].split('.'); // 'name.ext'

    return FileData(
      name: fileNameParts[0], // 파일 이름
      type: ".${fileNameParts[1]}", // 확장자
      content: fileParts[1], // Base64 인코딩된 콘텐츠
    );
  }

// Native 환경 파일 파싱
  FileData _parseNativeFileData(File file) {
    final fileName = path.basename(file.path);
    final fileType = path.extension(file.path);

    return FileData(
      name: path.basenameWithoutExtension(fileName), // 파일 이름
      type: fileType, // 확장자
      content: base64Encode(file.readAsBytesSync()), // Base64로 인코딩된 콘텐츠
    );
  }

  Future<void> loadCurrentFileData() async {
    if (_currentIndex < 0 || _currentIndex >= _fileDataList.length) {
      return;
    }

    final fileData = _fileDataList[_currentIndex];
    fileData.fileType = determineFileType(fileData.type); // 파일 유형 판별
    _currentFileData = fileData;

    // 파일 유형에 따라 데이터를 로드
    switch (fileData.fileType) {
      case FileType.series:
        fileData.seriesData = await _loadSeriesDataFromString(fileData.content);
        break;

      case FileType.object:
        fileData.objectData = await _loadObjectDataFromString(fileData.content);
        break;

      case FileType.image:
        // 이미지 데이터는 추가적인 로드 필요 없음 (이미 Base64로 제공됨)
        break;

      default:
        // 지원되지 않는 파일 형식 처리
        break;
    }

    // notifyListeners(); // UI 갱신
  }

// 파일 유형 판별 메서드
  FileType determineFileType(String extension) {
    if (seriesExtensions.contains(extension.toLowerCase())) return FileType.series;
    if (objectExtensions.contains(extension.toLowerCase())) return FileType.object;
    if (imageExtensions.contains(extension.toLowerCase())) return FileType.image;
    return FileType.unsupported;
  }

  /////////////////////////////////////////////////////////////////////////////////////////////

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
    if (dataIndex < 0 || dataIndex >= _fileDataList.length) return;
    final dataId = _fileDataList[dataIndex].name;

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
    if (_currentIndex < _fileDataList.length - 1) {
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
    return await StorageHelper().downloadLabelsAsZip(project, _labelEntries, _fileDataList);
  }
}
