import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // For generating unique project IDs
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/proxy_share_helper/interface_share_helper.dart';
import '../utils/storage_helper.dart';

class ProjectViewModel extends ChangeNotifier {
  Project project;
  final StorageHelperInterface storageHelper;
  final ShareHelperInterface shareHelper;

  ProjectViewModel({required this.storageHelper, required this.shareHelper, Project? project})
      : project = project ??
            Project(
              id: project?.id ?? const Uuid().v4(),
              name: project?.name ?? '',
              mode: project?.mode ?? LabelingMode.singleClassification,
              classes: project?.classes ?? [],
            );

  // ==============================
  // 📌 **프로젝트 기본 정보 관리**
  // ==============================

  /// ✅ 프로젝트 이름 변경
  void setName(String name) {
    project = project.copyWith(name: name);
    notifyListeners();
  }

  /// ✅ 라벨링 모드 변경
  void setLabelingMode(LabelingMode mode) async {
    if (project.mode != mode) {
      await storageHelper.deleteProjectLabels(project.id);
    }
    project = project.copyWith(mode: mode);
    notifyListeners();
  }

  /// ✅ 클래스 추가
  void addClass(String className) {
    if (!project.classes.contains(className)) {
      project = project.copyWith(classes: [...project.classes, className]);
      notifyListeners();
    }
  }

  /// ✅ 클래스 제거
  void removeClass(int index) {
    if (index >= 0 && index < project.classes.length) {
      List<String> updatedClasses = List.from(project.classes)..removeAt(index);
      project = project.copyWith(classes: updatedClasses);
      notifyListeners();
    }
  }

  /// ✅ 데이터 경로 추가
  void addDataPath(DataPath dataPath) {
    project = project.copyWith(dataPaths: [...project.dataPaths, dataPath]);
    notifyListeners();
  }

  // ==============================
  // 📌 **설정 변경 감지**
  // ==============================

  /// ✅ 기존 프로젝트와 라벨링 모드가 변경되었는지 확인
  bool isLabelingModeChanged() {
    return project.mode != project.mode;
  }

  // ==============================
  // 📌 **프로젝트 저장 및 삭제**
  // ==============================

  /// ✅ 프로젝트 저장 (신규/업데이트)
  Future<void> saveProject(bool isNew) async {
    List<Project> projects = await storageHelper.loadProjectFromConfig("projects");

    if (isNew) {
      projects.add(project);
    } else {
      int index = projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        projects[index] = project;
      }
    }

    await storageHelper.saveProjectConfig(projects);
    notifyListeners();
  }

  /// ✅ 프로젝트 삭제
  Future<void> deleteProject() async {
    List<Project> projects = await storageHelper.loadProjectFromConfig("projects");
    projects.removeWhere((p) => p.id == project.id);

    await storageHelper.saveProjectConfig(projects);
    notifyListeners();
  }

  // ==============================
  // 📌 **프로젝트 데이터 초기화**
  // ==============================

  /// ✅ 프로젝트의 기존 데이터 제거
  Future<void> clearProjectData() async {
    await storageHelper.deleteProjectLabels(project.id);
    notifyListeners();
  }

  // ==============================
  // 📌 **다운로드 & 공유 기능**
  // ==============================

  /// ✅ 프로젝트 설정 다운로드
  Future<void> downloadProjectConfig() async {
    await storageHelper.downloadProjectConfig(project);
  }

  /// ✅ 프로젝트 공유
  Future<void> shareProject(BuildContext context) async {
    try {
      final jsonString = project.toJsonString();
      await shareHelper.shareProject(
        name: project.name,
        jsonString: jsonString,
        getFilePath: () => storageHelper.downloadProjectConfig(project),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share project: $e')),
        );
      }
    }
  }
}
