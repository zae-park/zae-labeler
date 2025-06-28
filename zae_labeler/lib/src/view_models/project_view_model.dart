import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/models/data_model.dart';
import '../core/models/label_model.dart';
import '../core/models/project_model.dart';
import '../platform_helpers/share/interface_share_helper.dart';

import '../core/use_cases/project/project_use_cases.dart';

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
/// ├── clearProjectLabels()                    // 라벨 초기화
/// │
/// ├── downloadProjectConfig()               // 설정 다운로드
/// └── shareProject(BuildContext)            // 프로젝트 공유

class ProjectViewModel extends ChangeNotifier {
  Project project;
  final ShareHelperInterface shareHelper;
  final ProjectUseCases useCases;

  final void Function(Project updated)? onChanged;
  late final LabelingMode _initialMode;

  ProjectViewModel({required this.shareHelper, required this.useCases, this.onChanged, Project? project})
      : project = project ??
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

  Future<void> setName(String name) async {
    final updated = await useCases.edit.rename(project.id, name);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  Future<void> setLabelingMode(LabelingMode mode) async {
    if (project.mode != mode) {
      project = (await useCases.edit.changeLabelingMode(project.id, mode))!;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  Future<void> addClass(String className) async {
    project = await useCases.classList.addClass(project.id, className);
    notifyListeners();
    onChanged?.call(project);
  }

  Future<void> editClass(int index, String newName) async {
    useCases.classList.editClass(project.id, index, newName);
  }

  Future<void> removeClass(int index) async {
    project = await useCases.classList.removeClass(project.id, index);
    notifyListeners();
    onChanged?.call(project);
  }

  Future<void> addDataInfo(DataInfo dataInfo) async {
    project = await useCases.dataInfo.addData(projectId: project.id, dataInfo: dataInfo);
    notifyListeners();
    onChanged?.call(project);
  }

  Future<void> removeDataInfo(String dataId) async {
    final index = project.dataInfos.indexWhere((e) => e.id == dataId);
    if (index != -1) {
      project = await useCases.dataInfo.removeData(projectId: project.id, dataIndex: index);
      notifyListeners();
      onChanged?.call(project);
    }
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
    await useCases.io.saveOne(project);
    notifyListeners();
    onChanged?.call(project);
  }

  Future<void> clearProjectLabels() async {
    await useCases.edit.clearLabels(project.id);
    notifyListeners();
    onChanged?.call(project);
  }

  void updateFrom(Project updated) {
    project = updated;
    notifyListeners();
  }

  // ==============================
  // 📌 다운로드 및 공유
  // ==============================

  Future<void> shareProject(BuildContext context) async {
    try {
      await useCases.share.call(context, project);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ 프로젝트 공유에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> downloadProjectConfig() async {
    try {
      await useCases.repository.exportConfig(project);
    } catch (e) {
      debugPrint("❌ Failed to download config: $e");
    }
  }
}
