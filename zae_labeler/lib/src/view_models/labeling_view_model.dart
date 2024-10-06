// lib/src/view_models/labeling_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  List<Label> _labels = [];
  int _currentIndex = 0;
  List<String> _data = []; // 시계열 데이터 목록

  LabelingViewModel({required this.project}) {
    // 초기화 시 라벨 로드 및 데이터 로드
    loadLabels();
    loadData();
  }

  List<Label> get labels => _labels;
  int get currentIndex => _currentIndex;
  String get currentData => _data.isNotEmpty ? _data[_currentIndex] : '';

  // 라벨 로드
  Future<void> loadLabels() async {
    _labels = await StorageHelper.loadLabels();
    notifyListeners();
  }

  // 데이터 로드 (예시로 간단한 문자열 사용)
  void loadData() {
    // 실제 시계열 데이터 로드 로직 필요
    _data = List.generate(100, (index) => '데이터 $index');
    notifyListeners();
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
    if (_currentIndex < _data.length - 1) {
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

  // 다운로드 기능 (예시로 콘솔 출력)
  void downloadLabels() {
    // 실제 ZIP 압축 및 다운로드 로직 필요
    print('라벨링 데이터 다운로드');
  }
}
