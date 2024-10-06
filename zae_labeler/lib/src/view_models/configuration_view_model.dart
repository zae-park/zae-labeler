// lib/src/view_models/configuration_view_model.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart'; // 필요 시 유지
// import 'project_manager.dart'; // 사용되지 않으므로 제거

class ConfigurationViewModel extends ChangeNotifier {
  LabelingMode? _selectedMode;
  List<String> _classes = [];

  LabelingMode? get selectedMode => _selectedMode;
  List<String> get classes => _classes;

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

  // 설정 초기화
  void reset() {
    _selectedMode = null;
    _classes = [];
    notifyListeners();
  }
}
