// lib/src/view_models/labeling_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  List<Label> _labels = [];
  int _currentIndex = 0;
  List<File> _dataFiles = []; // 데이터 파일 목록
  List<double> _currentData = []; // 시계열 데이터

  LabelingViewModel({required this.project}) {
    // 초기화 시 라벨 로드 및 데이터 로드
    loadLabels();
    loadDataFiles();
  }

  List<Label> get labels => _labels;
  int get currentIndex => _currentIndex;
  List<File> get dataFiles => _dataFiles;
  List<double> get currentData => _currentData;
  String get currentFileName => _dataFiles.isNotEmpty
      ? path.basename(_dataFiles[_currentIndex].path)
      : '';
  String get currentLabel {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return '';
    }

    final dataId = _dataFiles[_currentIndex].path;
    final label = _labels.firstWhere((labelItem) => labelItem.dataId == dataId,
        orElse: () => Label(dataId: dataId, labels: []));

    return label.labels.join(', ');
  }

  // 라벨 로드
  Future<void> loadLabels() async {
    _labels = await StorageHelper.loadLabels();
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
  void addOrUpdateLabel(int dataIndex, String label) {
    if (dataIndex < 0 || dataIndex >= _dataFiles.length) return;
    final dataId = _dataFiles[dataIndex].path;

    final existingLabelIndex =
        _labels.indexWhere((labelItem) => labelItem.dataId == dataId);

    if (existingLabelIndex != -1) {
      // 이미 존재하는 라벨 업데이트
      _labels[existingLabelIndex].labels = [label];
    } else {
      // 새로운 라벨 추가
      _labels.add(Label(dataId: dataId, labels: [label]));
    }

    StorageHelper.saveLabels(_labels);
    notifyListeners();
  }

  // 현재 라벨이 선택되었는지 확인
  bool isLabelSelected(String label) {
    return currentLabel.contains(label);
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

  // 다운로드 기능: return the path instead of handling context
  Future<String> downloadLabelsAsZae() async {
    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/labels.zae');

    final zaeContent = _labels.map((label) => label.toJson()).toList();
    zaeFile.writeAsStringSync(jsonEncode(zaeContent));

    return zaeFile.path;
  }

  Future<String> downloadLabelsAsZip() async {
    final archive = Archive();

    for (var label in _labels) {
      final file = File(label.dataId);
      if (file.existsSync()) {
        final fileBytes = file.readAsBytesSync();
        archive.addFile(
            ArchiveFile(path.basename(file.path), fileBytes.length, fileBytes));
      }
    }

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
