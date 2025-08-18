// lib/src/features/project/view_models/configuration_view_model.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/use_cases/app_use_cases.dart';
import '../../label/models/label_model.dart' show LabelingMode; // 임시: 모드가 여기 있음
import '../../../core/models/project/project_model.dart';
import '../../../core/models/data/data_info.dart';

/// ✅ ConfigurationViewModel
/// - 프로젝트 생성/설정 화면에서 사용하는 상태 + 액션
/// - 기존 프로젝트 수정/저장은 Repository/UseCase로 위임
class ConfigurationViewModel extends ChangeNotifier {
  Project _project;
  final bool _isEditing;
  final AppUseCases appUseCases;

  /// 새 프로젝트 생성
  ConfigurationViewModel({required this.appUseCases})
      : _project = Project(
          id: const Uuid().v4(),
          name: '',
          mode: LabelingMode.singleClassification,
          classes: const ["True", "False"],
          dataInfos: const [],
        ),
        _isEditing = false;

  /// 기존 프로젝트 수정
  ConfigurationViewModel.fromProject(Project existingProject, {required this.appUseCases})
      : _project = existingProject.copyWith(),
        _isEditing = true;

  Project get project => _project.copyWith();
  bool get isEditing => _isEditing;

  // ──────────────────────────────────────────────────────────────────────────
  // 🏷️ 메타 편집
  // ──────────────────────────────────────────────────────────────────────────

  /// 프로젝트 이름 변경(Repo 저장까지)
  Future<void> setProjectName(String name) async {
    final updated = await appUseCases.project.rename(_project.id, name);
    if (updated != null) {
      _project = updated;
      notifyListeners();
    }
  }

  /// 라벨링 모드 변경
  /// 권장: ProjectUseCases.changeLabelingMode 내부에서 라벨 초기화까지 수행
  /// 만약 내부에서 라벨을 지우지 않는 설계라면 아래 주석을 해제:
  ///   await appUseCases.label.clearAll(_project.id);
  Future<void> setLabelingMode(LabelingMode mode) async {
    if (_project.mode == mode) return;
    final updated = await appUseCases.project.changeModeAndReset(_project.id, mode);
    if (updated != null) {
      _project = updated;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🧩 클래스 편집
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> addClass(String className) async {
    if (className.trim().isEmpty) return;
    if (_project.classes.contains(className)) return;

    List<String> updatedClasses = List<String>.from(_project.classes);
    updatedClasses.add(className.trim());

    final updated = await appUseCases.project.updateClasses(_project.id, updatedClasses);
    if (updated != null) {
      _project = updated;
      notifyListeners();
    }
  }

  Future<void> removeClass(int index) async {
    if (index < 0 || index >= _project.classes.length) return;

    List<String> updatedClasses = List<String>.from(_project.classes);
    updatedClasses.removeAt(index);

    final updated = await appUseCases.project.updateClasses(_project.id, updatedClasses);
    if (updated != null) {
      _project = updated;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 📂 데이터 추가/제거
  // ──────────────────────────────────────────────────────────────────────────

  /// 파일 선택 → DataInfo 생성 → Repo 반영(+로컬 동기화)
  Future<void> addDataInfo() async {
    final List<DataInfo> picked = [];

    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
      if (result != null) {
        for (final file in result.files) {
          final bytes = file.bytes;
          if (bytes == null) continue;
          final encoded = base64Encode(bytes);
          picked.add(DataInfo.create(fileName: file.name, base64Content: encoded));
        }
      }
    } else {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final dir = Directory(selectedDirectory);
        final files = dir.listSync().whereType<File>();
        for (final f in files) {
          final name = f.uri.pathSegments.last;
          picked.add(DataInfo.create(fileName: name, filePath: f.path));
        }
      }
    }

    if (picked.isEmpty) return;

    // 바로 Repo 반영 (되돌리기 UX가 필요하면 로컬만 변경하고 저장 시점에 한번에 반영)
    final updated = await appUseCases.project.addDataInfos(_project.id, picked);
    if (updated != null) {
      _project = updated;
      notifyListeners();
    }
  }

  /// 특정 인덱스의 DataInfo 제거
  Future<void> removeDataInfo(int index) async {
    if (index < 0 || index >= _project.dataInfos.length) return;

    final targetId = _project.dataInfos[index].id;
    final updated = await appUseCases.project.removeDataInfo(_project.id, targetId);
    if (updated != null) {
      _project = updated;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 💾 저장/리셋
  // ──────────────────────────────────────────────────────────────────────────

  /// 현재 화면 상태의 프로젝트를 저장(신규/기존 공통)
  Future<void> save() async {
    // ProjectUseCases에 save(Project) 또는 saveSnapshot 같은 메서드를 노출해두세요.
    // (없다면 추가 권장: repo.saveProject 위임)
    await appUseCases.project.save(_project);
  }

  /// 화면 상태 초기화
  void reset() {
    if (_isEditing) {
      _project = _project.copyWith();
    } else {
      _project = Project(id: const Uuid().v4(), name: 'Greeting! zae!', mode: LabelingMode.singleClassification, classes: const ["True", "False"]);
    }
    notifyListeners();
  }
}
