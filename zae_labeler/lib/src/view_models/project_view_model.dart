import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/data_model.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../utils/proxy_share_helper/interface_share_helper.dart';

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
  // 📌 **프로젝트 기본 정보 관리**
  // ==============================

  /// ✅ 프로젝트 이름 변경
  void setName(String name) {
    project = project.copyWith(name: name);
    notifyListeners();
  }

  /// ✅ 라벨링 모드 변경
  Future<void> setLabelingMode(LabelingMode mode) async {
    if (project.mode != mode) {
      await repository.clearLabels(project.id);
      project = project.copyWith(mode: mode);
      notifyListeners();
    }
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
      final updatedClasses = List<String>.from(project.classes)..removeAt(index);
      project = project.copyWith(classes: updatedClasses);
      notifyListeners();
    }
  }

  /// ✅ 데이터 정보 추가
  void addDataInfo(DataInfo dataInfo) {
    project = project.copyWith(dataInfos: [...project.dataInfos, dataInfo]);
    notifyListeners();
  }

  // ==============================
  // 📌 **설정 변경 감지**
  // ==============================

  /// ✅ 기존 프로젝트와 라벨링 모드가 변경되었는지 확인
  bool isLabelingModeChanged() {
    return project.mode != _initialMode;
  }

  // ==============================
  // 📌 **프로젝트 저장 및 삭제**
  // ==============================

  /// ✅ 프로젝트 저장 (신규/업데이트)
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

  /// ✅ 프로젝트 삭제
  Future<void> deleteProject() async {
    await repository.deleteById(project.id);
    notifyListeners();
  }

  // ==============================
  // 📌 **프로젝트 데이터 초기화**
  // ==============================

  /// ✅ 프로젝트의 기존 데이터 제거
  Future<void> clearProjectData() async {
    await repository.clearLabels(project.id);
    notifyListeners();
  }

  // ==============================
  // 📌 **다운로드 & 공유 기능**
  // ==============================

  /// ✅ 프로젝트 설정 다운로드
  Future<void> downloadProjectConfig() async {
    await repository.exportConfig(project);
  }

  /// ✅ 프로젝트 공유
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
