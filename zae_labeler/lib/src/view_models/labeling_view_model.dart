// lib/src/view_models/labeling_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  List<LabelEntry> _labelEntries = [];
  int _currentIndex = 0;
  List<File> _dataFiles = []; // 데이터 파일 목록
  List<double> _currentData = []; // 시계열 데이터

  LabelingViewModel({required this.project}) {
    // 초기화 시 라벨 로드 및 데이터 로드
    loadLabels();
    loadDataFiles();
  }

  List<LabelEntry> get labelEntries => _labelEntries;
  int get currentIndex => _currentIndex;
  List<File> get dataFiles => _dataFiles;
  List<double> get currentData => _currentData;
  String get currentFileName => _dataFiles.isNotEmpty
      ? path.basename(_dataFiles[_currentIndex].path)
      : '';
  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }

    final dataId = _dataFiles[_currentIndex].path;
    final entry =
        _labelEntries.firstWhere((labelEntry) => labelEntry.dataPath == dataId,
            orElse: () => LabelEntry(
                  dataFilename: path.basename(dataId),
                  dataPath: dataId,
                ));
    return entry;
  }

  // 라벨 로드
  Future<void> loadLabels() async {
    _labelEntries = await StorageHelper.loadLabelEntries();
    notifyListeners();
  }

  // 데이터 파일 로드 (특정 포맷만 필터링, 예: .csv)
  void loadDataFiles() {
    final directory = Directory(project.dataDirectory);
    if (directory.existsSync()) {
      _dataFiles = directory
          .listSync()
          .where((file) => file is File && path.extension(file.path) == '.csv')
          .cast<File>()
          .toList();
      if (_dataFiles.isNotEmpty) {
        loadCurrentData();
      }
    }
    notifyListeners();
  }

  // 현재 데이터 파일 로드 (예시로 CSV 파일의 첫 번째 열을 시계열 데이터로 사용)
  void loadCurrentData() {
    if (_currentIndex >= 0 && _currentIndex < _dataFiles.length) {
      final file = _dataFiles[_currentIndex];
      final lines = file.readAsLinesSync();
      _currentData = lines.map((line) {
        final parts = line.split(',');
        return double.tryParse(parts[0]) ?? 0.0;
      }).toList();
    }
    notifyListeners();
  }

  // 라벨 추가 또는 수정
  void addOrUpdateLabel(int dataIndex, String label, String mode) {
    if (dataIndex < 0 || dataIndex >= _dataFiles.length) return;
    final dataId = _dataFiles[dataIndex].path;

    final existingEntryIndex =
        _labelEntries.indexWhere((entry) => entry.dataPath == dataId);

    if (existingEntryIndex != -1) {
      // 이미 존재하는 엔트리 업데이트
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
              entry.multiClassification!.labeledAt =
                  DateTime.now().toIso8601String();
            }
          }
          break;
        case 'segmentation':
          // Segmentation 라벨 추가 로직 필요
          // 예시로, 분리된 인덱스와 클래스 리스트를 입력받는다고 가정
          // 실제 구현은 사용자의 요구에 따라 달라질 수 있습니다.
          break;
        default:
          break;
      }
    } else {
      // 새로운 엔트리 추가
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

    StorageHelper.saveLabelEntries(_labelEntries);
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

  // 데이터 이동
  void moveNext() {
    if (_currentIndex < _dataFiles.length - 1) {
      _currentIndex++;
      loadCurrentData();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      loadCurrentData();
    }
  }

  // 다운로드 기능: path 반환
  Future<String> downloadLabelsAsZae() async {
    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/labels.zae');

    final zaeContent =
        _labelEntries.map((labelEntry) => labelEntry.toJson()).toList();
    zaeFile.writeAsStringSync(jsonEncode(zaeContent));

    return zaeFile.path;
  }

  Future<String> downloadLabelsAsZip() async {
    final archive = Archive();

    // 데이터 파일을 아카이브에 추가
    for (var file in _dataFiles) {
      if (file.existsSync()) {
        final fileBytes = file.readAsBytesSync();
        archive.addFile(
            ArchiveFile(path.basename(file.path), fileBytes.length, fileBytes));
      }
    }

    // labels.json을 아카이브에 추가
    final labelsJson =
        jsonEncode(_labelEntries.map((e) => e.toJson()).toList());
    archive.addFile(ArchiveFile('labels.json', labelsJson.length,
        utf8.encode(labelsJson))); // labels.json 파일 추가

    // 아카이브를 ZIP으로 인코딩
    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      final directory = await getApplicationDocumentsDirectory();
      final zipFile = File('${directory.path}/labels.zip');
      zipFile.writeAsBytesSync(zipData);
      return zipFile.path;
    } else {
      throw Exception('ZIP 생성 실패');
    }
  }
}
