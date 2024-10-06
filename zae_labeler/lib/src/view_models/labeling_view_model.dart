// lib/src/view_models/labeling_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  List<Label> _labels = [];
  int _currentIndex = 0;
  List<File> _dataFiles = []; // 시계열 데이터 파일 목록
  List<String> _dataContents = []; // 시계열 데이터 내용 (예시로 문자열 사용)

  LabelingViewModel({required this.project}) {
    // 초기화 시 라벨 로드 및 데이터 로드
    loadLabels();
    loadDataFiles();
  }

  List<Label> get labels => _labels;
  int get currentIndex => _currentIndex;
  String get currentData =>
      _dataContents.isNotEmpty ? _dataContents[_currentIndex] : '';

  // 라벨 로드
  Future<void> loadLabels() async {
    _labels = await StorageHelper.loadLabels();
    notifyListeners();
  }

  // 데이터 파일 로드
  Future<void> loadDataFiles() async {
    final directory = Directory(project.dataDirectory);
    if (await directory.exists()) {
      // 특정 포맷 (예: .csv) 필터링
      _dataFiles = directory
          .listSync()
          .where((file) => file is File && path.extension(file.path) == '.csv')
          .map((file) => file as File)
          .toList();
      // 파일 내용 읽기 (여기서는 간단히 문자열로 가정)
      _dataContents = await Future.wait(
          _dataFiles.map((file) async => await file.readAsString()));
      notifyListeners();
    } else {
      // 디렉토리가 존재하지 않을 경우 빈 리스트
      _dataFiles = [];
      _dataContents = [];
      notifyListeners();
    }
  }

  // 라벨 추가 또는 수정
  void addOrUpdateLabel(String dataId, String label) {
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
    if (_currentIndex < _dataContents.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  // .zae 파일 저장 (라벨링 데이터 포함)
  Future<void> saveZaeFile() async {
    // 라벨링 데이터를 JSON 형식으로 변환
    Map<String, dynamic> labelingData = {
      'project': project.toJson(),
      'labels': _labels.map((label) => label.toJson()).toList(),
    };
    String jsonString = jsonEncode(labelingData);

    // .zae 파일 저장 위치
    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/${project.name}.zae');

    await zaeFile.writeAsString(jsonString);
  }

  // ZIP 압축 및 다운로드
  Future<void> downloadLabels() async {
    // ZIP 압축할 파일 목록 준비 (.zae 파일 포함)
    await saveZaeFile(); // 먼저 .zae 파일 저장

    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/${project.name}.zae');

    if (await zaeFile.exists()) {
      // ZIP 파일 생성
      final archive = Archive();
      final zaeBytes = await zaeFile.readAsBytes();
      archive.addFile(
          ArchiveFile(path.basename(zaeFile.path), zaeBytes.length, zaeBytes));

      // ZIP 파일 바이너리 생성
      final zipData = ZipEncoder().encode(archive)!;

      // 임시 디렉토리에 ZIP 파일 저장
      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/${project.name}.zip');
      await zipFile.writeAsBytes(zipData);

      // 파일 공유 또는 다운로드 (여기서는 공유 기능 사용)
      await Share.shareFiles([zipFile.path], text: '라벨링 데이터입니다.');
    } else {
      // .zae 파일이 존재하지 않을 경우 에러 처리
      // 예: 스낵바로 사용자에게 알림
    }
  }

  // ZIP 압축 없이 .zae 파일만 다운로드
  Future<void> downloadWithoutZip() async {
    // .zae 파일 직접 저장 또는 공유
    await saveZaeFile();
    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/${project.name}.zae');

    if (await zaeFile.exists()) {
      // 파일 공유 또는 다운로드
      await Share.shareFiles([zaeFile.path], text: '라벨링 데이터입니다.');
    } else {
      // .zae 파일이 존재하지 않을 경우 에러 처리
    }
  }
}
