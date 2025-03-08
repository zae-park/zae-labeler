// lib/src/view_models/configuration_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart'; // 프로젝트 ID 생성
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';

/// ✅ **ConfigurationViewModel**
/// - 새로운 프로젝트 생성 및 설정을 관리하는 ViewModel
/// - 기존 프로젝트 수정은 `ProjectViewModel`에서 처리
class ConfigurationViewModel extends ChangeNotifier {
  String _projectName;
  LabelingMode _selectedMode;
  List<String> _classes;
  List<DataPath> _dataPaths;

  // 기본 생성자 (새 프로젝트 생성용)
  ConfigurationViewModel()
      : _projectName = "",
        _selectedMode = LabelingMode.singleClassification,
        _classes = ['1', '2', '3'],
        _dataPaths = [];

  // 🔥 기존 프로젝트 수정용 생성자 추가
  ConfigurationViewModel.fromProject(Project project)
      : _projectName = project.name,
        _selectedMode = project.mode,
        _classes = List.from(project.classes),
        _dataPaths = List.from(project.dataPaths);

  String get projectName => _projectName;
  LabelingMode get selectedMode => _selectedMode;
  List<String> get classes => _classes;
  List<DataPath> get dataPaths => _dataPaths;

  /// ✅ 프로젝트 이름 설정
  void setProjectName(String name) {
    _projectName = name;
    notifyListeners();
  }

  /// ✅ 라벨링 모드 설정
  void setLabelingMode(LabelingMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  /// ✅ 클래스 추가
  void addClass(String className) {
    if (_classes.length < 10 && !_classes.contains(className)) {
      _classes.add(className);
      notifyListeners();
    }
  }

  /// ✅ 클래스 제거
  void removeClass(int index) {
    _classes.removeAt(index);
    notifyListeners();
  }

  /// ✅ 데이터 경로 추가
  Future<void> addDataPath() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);

      if (result != null) {
        for (var file in result.files) {
          _dataPaths.add(DataPath(fileName: file.name, base64Content: base64Encode(file.bytes ?? [])));
        }
        notifyListeners();
      }
    } else {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        final files = directory.listSync().whereType<File>();
        for (var file in files) {
          _dataPaths.add(DataPath(fileName: file.uri.pathSegments.last, filePath: file.path));
        }
        notifyListeners();
      }
    }
  }

  /// ✅ 새로운 프로젝트 생성
  Project createProject() {
    return Project(
      id: const Uuid().v4(), // UUID를 사용하여 고유 ID 생성
      name: _projectName,
      mode: _selectedMode,
      classes: _classes,
      dataPaths: _dataPaths,
    );
  }

  /// ✅ 프로젝트 설정 초기화
  void reset() {
    _projectName = "";
    _selectedMode = LabelingMode.singleClassification;
    _classes = ['1', '2', '3'];
    _dataPaths = [];
    notifyListeners();
  }
}
