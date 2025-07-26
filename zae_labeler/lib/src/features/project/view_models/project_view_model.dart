import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/features/label/view_models/labeling_view_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/get_storage_helper.dart';

import '../../../core/models/data_model.dart';
import '../../label/models/label_model.dart';
import '../models/project_model.dart';
import '../../../platform_helpers/share/interface_share_helper.dart';

import '../use_cases/project_use_cases.dart';

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

  // ────────────────────────────────────────────
  // 📦 진행률 정보를 위한 필드
  // ────────────────────────────────────────────
  double progressRatio = 0.0;
  int completeCount = 0;
  int warningCount = 0;
  int incompleteCount = 0;
  bool progressLoaded = false;

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

  /// 진행률 정보를 로딩하는 메서드
  /// // LabelingViewModel을 생성하여 진행률 정보를 얻는다.
  Future<void> loadProgress(StorageHelperInterface helper, AppUseCases appUseCases) async {
    final labelingVM = await LabelingViewModelFactory.createAsync(project, helper, appUseCases);
    progressRatio = labelingVM.progressRatio;
    completeCount = labelingVM.completeCount;
    warningCount = labelingVM.warningCount;
    incompleteCount = labelingVM.incompleteCount;
    progressLoaded = true;
    labelingVM.dispose();
    notifyListeners();
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
        GlobalAlertManager.show(context, '⚠️ 프로젝트 공유에 실패했습니다: $e', type: AlertType.error);
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
