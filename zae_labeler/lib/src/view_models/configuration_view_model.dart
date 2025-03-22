// lib/src/view_models/configuration_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart'; // 프로젝트 ID 생성
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';

/// ✅ **ConfigurationViewModel**
/// - 프로젝트 생성 및 설정을 관리하는 ViewModel
/// - 기존 프로젝트 수정은 `ProjectViewModel`에서 처리
class ConfigurationViewModel extends ChangeNotifier {
  Project _project;
  final bool _isEditing; // ✅ 기존 프로젝트 수정 여부 플래그

  // ✅ 새 프로젝트 생성 시 기본값 설정
  ConfigurationViewModel()
      : _project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: ["True", "False"], dataPaths: []),
        _isEditing = false;

  // ✅ 기존 프로젝트 수정용 생성자
  ConfigurationViewModel.fromProject(Project existingProject)
      : _project = existingProject,
        _isEditing = true;

  Project get project => _project;
  bool get isEditing => _isEditing; // ✅ 수정 모드 여부 반환

  /// ✅ 프로젝트 이름 설정
  void setProjectName(String name) {
    _project = _project.copyWith(name: name);
    notifyListeners();
  }

  /// ✅ 라벨링 모드 설정
  void setLabelingMode(LabelingMode mode) {
    _project = _project.copyWith(mode: mode);
    notifyListeners();
  }

  /// ✅ 클래스 추가
  void addClass(String className) {
    if (!_project.classes.contains(className)) {
      _project = _project.copyWith(classes: [..._project.classes, className]);
      notifyListeners();
    }
  }

  /// ✅ 클래스 제거
  void removeClass(int index) {
    if (index >= 0 && index < _project.classes.length) {
      _project = _project.copyWith(classes: List.from(_project.classes)..removeAt(index));
      notifyListeners();
    }
  }

  /// ✅ 데이터 경로 추가
  Future<void> addDataPath() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);

      if (result != null) {
        for (var file in result.files) {
          _project = _project.copyWith(dataPaths: [..._project.dataPaths, DataPath(fileName: file.name, base64Content: base64Encode(file.bytes ?? []))]);
        }
        notifyListeners();
      }
    } else {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        final files = directory.listSync().whereType<File>();
        for (var file in files) {
          _project = _project.copyWith(dataPaths: [..._project.dataPaths, DataPath(fileName: file.uri.pathSegments.last, filePath: file.path)]);
        }
        notifyListeners();
      }
    }
  }

  /// ✅ 데이터 경로 삭제 기능 추가
  void removeDataPath(int index) {
    if (index >= 0 && index < _project.dataPaths.length) {
      _project = _project.copyWith(dataPaths: List.from(_project.dataPaths)..removeAt(index));
      notifyListeners();
    }
  }

  /// ✅ 프로젝트 설정 초기화
  void reset() {
    if (_isEditing) {
      _project = _project.copyWith(); // ✅ 기존 프로젝트 수정 모드일 경우 초기화하지 않음
    } else {
      _project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: [], dataPaths: []);
    }
    notifyListeners();
  }
}
