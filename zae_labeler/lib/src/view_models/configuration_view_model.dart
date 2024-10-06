// lib/src/view_models/configuration_view_model.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ConfigurationViewModel extends ChangeNotifier {
  LabelingMode? _selectedMode;
  List<String> _classes = [];
  String _dataDirectory = ''; // 데이터 디렉토리 경로

  LabelingMode? get selectedMode => _selectedMode;
  List<String> get classes => _classes;
  String get dataDirectory => _dataDirectory;

  // 라벨링 모드 선택
  void selectMode(LabelingMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  // 클래스 추가
  void addClass(String className) {
    if (_classes.length < 10 && !_classes.contains(className)) {
      _classes.add(className);
      notifyListeners();
    }
  }

  // 클래스 제거
  void removeClass(String className) {
    _classes.remove(className);
    notifyListeners();
  }

  // 데이터 디렉토리 설정
  Future<void> setDataDirectory() async {
    // 권한 요청
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        // 권한이 거부된 경우 사용자에게 알림
        // 예: 스낵바로 알림
        // 이 부분은 View에서 처리하거나 다른 방법으로 구현
        return;
      }
    }

    // 디렉토리 선택 다이얼로그 열기
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _dataDirectory = selectedDirectory;
      notifyListeners();
    }
  }

  // 설정 초기화
  void reset() {
    _selectedMode = null;
    _classes = [];
    _dataDirectory = '';
    notifyListeners();
  }
}
