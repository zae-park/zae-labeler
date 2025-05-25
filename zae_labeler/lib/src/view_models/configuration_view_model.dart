// lib/src/view_models/configuration_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart'; // 프로젝트 ID 생성
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/storage_helper.dart';

/// ✅ **ConfigurationViewModel**
/// - 프로젝트 생성 및 설정을 관리하는 ViewModel
/// - 기존 프로젝트 수정은 `ProjectViewModel`에서 처리
class ConfigurationViewModel extends ChangeNotifier {
  Project _project;
  final bool _isEditing; // ✅ 기존 프로젝트 수정 여부 플래그

  // ✅ 새 프로젝트 생성 시 기본값 설정
  ConfigurationViewModel()
      : _project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: ["True", "False"], dataInfos: []),
        _isEditing = false;

  // ✅ 기존 프로젝트 수정용 생성자
  ConfigurationViewModel.fromProject(Project existingProject)
      : _project = existingProject.copyWith(),
        _isEditing = true;

  Project get project => _project.copyWith();
  bool get isEditing => _isEditing; // ✅ 수정 모드 여부 반환

  /// ✅ 프로젝트 이름 설정
  void setProjectName(String name) {
    _project = _project.copyWith(name: name);
    notifyListeners();
  }

  /// ✅ 라벨링 모드 설정
  void setLabelingMode(LabelingMode mode) {
    if (_project.mode != mode) {
      StorageHelper.instance.deleteProjectLabels(_project.id);
      _project = _project.copyWith(mode: mode);
    }

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
  Future<void> addDataInfo() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);

      if (result != null) {
        for (var file in result.files) {
          _project = _project.copyWith(dataInfos: [..._project.dataInfos, DataInfo(fileName: file.name, base64Content: base64Encode(file.bytes ?? []))]);
        }
        notifyListeners();
      }
    } else {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        final files = directory.listSync().whereType<File>();
        for (var file in files) {
          _project = _project.copyWith(dataInfos: [..._project.dataInfos, DataInfo(fileName: file.uri.pathSegments.last, filePath: file.path)]);
        }
        notifyListeners();
      }
    }
  }

  /// ✅ 데이터 정보 삭제 기능 추가
  void removeDataInfo(int index) {
    if (index >= 0 && index < _project.dataInfos.length) {
      _project = _project.copyWith(dataInfos: List.from(_project.dataInfos)..removeAt(index));
      notifyListeners();
    }
  }

  /// ✅ 프로젝트 설정 초기화
  void reset() {
    if (_isEditing) {
      _project = _project.copyWith(); // ✅ 기존 프로젝트 수정 모드일 경우 초기화하지 않음
    } else {
      _project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: [], dataInfos: []);
    }
    notifyListeners();
  }
}
