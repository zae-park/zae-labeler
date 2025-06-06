import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/data_model.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../utils/proxy_share_helper/interface_share_helper.dart';

/// 🔧 ViewModel: 단일 프로젝트를 관리
/// ProjectViewModel
/// ├── setName(String)                        // 프로젝트 이름 변경
/// ├── setLabelingMode(LabelingMode)         // 라벨링 모드 변경 (라벨 초기화 포함)
/// ├── addClass(String)                       // 클래스 추가
/// ├── editClass(int, String)                // 클래스 이름 수정
/// ├── removeClass(int)                      // 클래스 제거
/// ├── addDataInfo(DataInfo)                 // 데이터 추가
/// ├── removeDataInfo(String)                // 데이터 제거
/// │
/// ├── isLabelingModeChanged()               // 모드 변경 여부 확인
/// │
/// ├── saveProject(bool)                     // 프로젝트 저장 (신규/업데이트)
/// ├── deleteProject()                       // 프로젝트 삭제
/// ├── clearProjectData()                    // 라벨 초기화
/// │
/// ├── downloadProjectConfig()               // 설정 다운로드
/// └── shareProject(BuildContext)            // 프로젝트 공유

class ProjectViewModel extends ChangeNotifier {
  Project project;
  final ProjectRepository repository;
  final ShareHelperInterface shareHelper;

  late final LabelingMode _initialMode;

  ProjectViewModel({
    required this.repository,
    required this.shareHelper,
    Project? project,
  }) : project = project ??
            Project(
              id: project?.id ?? const Uuid().v4(),
              name: project?.name ?? '',
              mode: project?.mode ?? LabelingMode.singleClassification,
              classes: project?.classes ?? [],
            ) {
    _initialMode = this.project.mode;
  }

  // ==============================
  // 📌 프로젝트 정보 수정
  // ==============================

  void setName(String name) {
    project = project.copyWith(name: name);
    notifyListeners();
  }

  Future<void> setLabelingMode(LabelingMode mode) async {
    if (project.mode != mode) {
      await repository.clearLabels(project.id);
      project = project.copyWith(mode: mode);
      notifyListeners();
    }
  }

  void addClass(String className) {
    if (!project.classes.contains(className)) {
      project = project.copyWith(classes: [...project.classes, className]);
      notifyListeners();
    }
  }

  void editClass(int index, String newName) {
    if (index >= 0 && index < project.classes.length) {
      final updated = List<String>.from(project.classes)..[index] = newName;
      project = project.copyWith(classes: updated);
      notifyListeners();
    }
  }

  void removeClass(int index) {
    if (index >= 0 && index < project.classes.length) {
      final updatedClasses = List<String>.from(project.classes)..removeAt(index);
      project = project.copyWith(classes: updatedClasses);
      notifyListeners();
    }
  }

  void addDataInfo(DataInfo dataInfo) {
    project = project.copyWith(dataInfos: [...project.dataInfos, dataInfo]);
    notifyListeners();
  }

  void removeDataInfo(String dataId) {
    final updated = project.dataInfos.where((e) => e.id != dataId).toList();
    project = project.copyWith(dataInfos: updated);
    notifyListeners();
  }

  // ==============================
  // 📌 변경 감지
  // ==============================

  bool isLabelingModeChanged() {
    return project.mode != _initialMode;
  }

  // ==============================
  // 📌 저장 / 삭제 / 초기화
  // ==============================

  Future<void> saveProject(bool isNew) async {
    final current = await repository.fetchAllProjects();
    final index = current.indexWhere((p) => p.id == project.id);

    if (isNew) {
      current.add(project);
    } else if (index != -1) {
      current[index] = project;
    }

    await repository.saveAll(current);
    notifyListeners();
  }

  Future<void> deleteProject() async {
    await repository.deleteById(project.id);
    notifyListeners();
  }

  Future<void> clearProjectData() async {
    await repository.clearLabels(project.id);
    notifyListeners();
  }

  // ==============================
  // 📌 다운로드 및 공유
  // ==============================

  Future<void> downloadProjectConfig() async {
    await repository.exportConfig(project);
  }

  Future<void> shareProject(BuildContext context) async {
    try {
      final jsonString = project.toJsonString();
      await shareHelper.shareProject(
        name: project.name,
        jsonString: jsonString,
        getFilePath: () => repository.exportConfig(project),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ 프로젝트 공유에 실패했습니다: $e')),
        );
      }
    }
  }
}
