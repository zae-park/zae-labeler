// lib/src/view_models/configuration_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart'; // 프로젝트 ID 생성
import '../core/use_cases/app_use_cases.dart';
import '../core/models/label_model.dart';
import '../core/models/project_model.dart';
import '../core/models/data_model.dart';

/// ✅ **ConfigurationViewModel**
/// - 프로젝트 생성 및 설정을 관리하는 ViewModel
/// - 기존 프로젝트 수정은 `ProjectViewModel`에서 처리
class ConfigurationViewModel extends ChangeNotifier {
  Project _project;
  final bool _isEditing; // ✅ 기존 프로젝트 수정 여부 플래그
  final AppUseCases appUseCases;

  // ✅ 새 프로젝트 생성 시 기본값 설정
  ConfigurationViewModel({required this.appUseCases})
      : _project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: ["True", "False"], dataInfos: []),
        _isEditing = false;

  // ✅ 기존 프로젝트 수정용 생성자
  ConfigurationViewModel.fromProject(Project existingProject, {required this.appUseCases})
      : _project = existingProject.copyWith(),
        _isEditing = true;

  Project get project => _project.copyWith();
  bool get isEditing => _isEditing; // ✅ 수정 모드 여부 반환

  /// ✅ 프로젝트 이름 설정
  Future<void> setProjectName(String name) async {
    await appUseCases.project.edit.rename(_project.id, name);
    _project = _project.copyWith(name: name);
    notifyListeners();
  }

  /// ✅ 라벨링 모드 설정
  Future<void> setLabelingMode(LabelingMode mode) async {
    if (_project.mode != mode) {
      debugPrint("🧹 LabelingMode 변경 감지 → 기존 라벨 삭제");
      await appUseCases.project.edit.changeLabelingMode(_project.id, mode);
      await appUseCases.label.repository.deleteAllLabels(_project.id);
      _project = _project.copyWith(mode: mode);
      notifyListeners();
    }
  }

  /// ✅ 클래스 추가
  Future<void> addClass(String className) async {
    if (!_project.classes.contains(className)) {
      await appUseCases.project.classList.addClass(_project.id, className);
      _project = _project.copyWith(classes: [..._project.classes, className]);
      notifyListeners();
    }
  }

  /// ✅ 클래스 제거
  Future<void> removeClass(int index) async {
    if (index >= 0 && index < _project.classes.length) {
      await appUseCases.project.classList.removeClass(_project.id, index);
      _project = _project.copyWith(classes: List.from(_project.classes)..removeAt(index));
      notifyListeners();
    }
  }

  /// ✅ 데이터 경로 추가
  Future<void> addDataInfo() async {
    final List<DataInfo> newDataInfos = [];

    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
      if (result != null) {
        for (final file in result.files) {
          final encoded = base64Encode(file.bytes ?? []);
          newDataInfos.add(DataInfo(fileName: file.name, base64Content: encoded));
        }
      }
    } else {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        final files = directory.listSync().whereType<File>();
        for (final file in files) {
          final name = file.uri.pathSegments.last;
          newDataInfos.add(DataInfo(fileName: name, filePath: file.path));
        }
      }
    }

    if (newDataInfos.isNotEmpty) {
      _project = _project.copyWith(dataInfos: [..._project.dataInfos, ...newDataInfos]);
      notifyListeners();
    }
  }

  /// ✅ 데이터 정보 삭제 기능 추가
  void removeDataInfo(int index) {
    if (index >= 0 && index < _project.dataInfos.length) {
      final updatedList = List<DataInfo>.from(_project.dataInfos)..removeAt(index);
      _project = _project.copyWith(dataInfos: updatedList);
      notifyListeners();
    }
  }

  /// ✅ 프로젝트 설정 초기화
  void reset() {
    if (_isEditing) {
      _project = _project.copyWith();
    } else {
      _project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: [], dataInfos: []);
    }
    notifyListeners();
  }
}
