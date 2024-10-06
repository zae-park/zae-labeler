// lib/src/view_models/labeling_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // jsonEncode를 사용하기 위해 추가

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

    final existingLabel = _labels.firstWhere(
        (labelItem) => labelItem.dataId == dataId,
        orElse: () => Label(dataId: dataId, labels: []));

    if (project.mode == LabelingMode.singleClassification ||
        project.mode == LabelingMode.segmentation) {
      // 싱글 라벨링 또는 세그멘테이션의 경우 기존 라벨 덮어쓰기
      if (existingLabel.labels.isNotEmpty) {
        existingLabel.labels[0] = label;
      } else {
        existingLabel.labels.add(label);
      }
    } else if (project.mode == LabelingMode.multiClassification) {
      // 멀티 라벨링의 경우 라벨 추가
      if (!existingLabel.labels.contains(label)) {
        existingLabel.labels.add(label);
      }
    }

    // 기존에 없으면 추가
    if (!_labels.contains(existingLabel)) {
      _labels.add(existingLabel);
    }

    StorageHelper.saveLabels(_labels);
    notifyListeners();
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

  // ZIP 압축 후 다운로드
  Future<void> downloadLabelsAsZip() async {
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
      Share.shareXFiles([XFile(zipFile.path)], text: '라벨링 데이터 ZIP 파일입니다.');
    }
  }

  // .zae 파일만 다운로드
  Future<void> downloadLabelsAsZae() async {
    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/labels.zae');

    final zaeContent = _labels.map((label) => label.toJson()).toList();
    zaeFile.writeAsStringSync(jsonEncode(zaeContent));

    Share.shareXFiles([XFile(zaeFile.path)], text: '라벨링 데이터 .zae 파일입니다.');
  }
}
