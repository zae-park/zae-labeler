// lib/src/view_models/configuration_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/label_models/label_model.dart';
import '../models/project_model.dart';

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
    // 디렉토리 선택 다이얼로그 열기
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _dataDirectory = selectedDirectory;
      notifyListeners();
    }
  }

  Future<Project?> importProjectConfig() async {
    try {
      // 파일 선택
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Web 환경: bytes 속성 사용
        final content = file.bytes != null ? utf8.decode(file.bytes!) : await File(file.path!).readAsString(); // Native 환경

        // JSON 디코딩 및 프로젝트 객체 생성
        final Map<String, dynamic> projectJson = jsonDecode(content);
        final project = Project.fromJson(projectJson);
        return project;
      }
    } catch (e) {
      debugPrint('Failed to import project: $e');
      return null;
    }
    return null;
  }

  // 설정 초기화
  void reset() {
    _selectedMode = null;
    _classes = [];
    _dataDirectory = '';
    notifyListeners();
  }
}
