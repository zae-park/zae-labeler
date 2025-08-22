// lib/src/features/project/view_models/project_view_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:zae_labeler/common/widgets/global_alert.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/features/label/view_models/labeling_view_model.dart';

import '../../../core/models/data/data_info.dart';
import '../../../core/models/label/label_model.dart' show LabelingMode; // 임시: 모드 여기 위치
import '../../../core/models/project/project_model.dart';

import '../../../platform_helpers/share/interface_share_helper.dart';
import '../../../platform_helpers/storage/interface_storage_helper.dart';

/// 🔧 ViewModel: 단일 프로젝트 화면 상태 & 액션
/// - 이름/모드/클래스/데이터 편집을 ProjectUseCases(파사드)로 위임
/// - 라벨 초기화/진행률/공유/다운로드 유틸 제공
class ProjectViewModel extends ChangeNotifier {
  Project project;
  final ShareHelperInterface shareHelper;
  final AppUseCases appUseCases;

  final void Function(Project updated)? onChanged;
  late final LabelingMode _initialMode;

  // ────────────────────────────────────────────
  // 📦 진행률 정보 (LabelingViewModel에서 계산)
  // ────────────────────────────────────────────
  double progressRatio = 0.0;
  int completeCount = 0;
  int warningCount = 0;
  int incompleteCount = 0;
  bool progressLoaded = false;

  ProjectViewModel({required this.shareHelper, required this.appUseCases, this.onChanged, Project? project})
      : project = project ??
            Project(
              id: project?.id ?? const Uuid().v4(),
              name: project?.name ?? '',
              mode: project?.mode ?? LabelingMode.singleClassification,
              classes: project?.classes ?? const [],
            ) {
    _initialMode = this.project.mode;
  }

  // ────────────────────────────────────────────
  // 📊 진행률 로딩
  // ────────────────────────────────────────────
  /// LabelingViewModel 팩토리를 사용해 현재 프로젝트의 진행률을 계산합니다.
  Future<void> loadProgress(StorageHelperInterface helper) async {
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
    final updated = await appUseCases.project.rename(project.id, name);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  /// 권장: 내부에서 라벨 초기화까지 수행하는 별칭 사용 (changeModeAndReset)
  Future<void> setLabelingMode(LabelingMode mode) async {
    if (project.mode == mode) return;
    final updated = await appUseCases.project.changeModeAndReset(project.id, mode);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  // ==============================
  // 🧩 클래스 편집 (전체 교체 방식)
  // ==============================

  Future<void> addClass(String className) async {
    final name = className.trim();
    if (name.isEmpty) return;
    if (project.classes.contains(name)) return;

    final next = List<String>.from(project.classes)..add(name);
    final updated = await appUseCases.project.updateClasses(project.id, next);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  Future<void> editClass(int index, String newName) async {
    if (index < 0 || index >= project.classes.length) return;
    final name = newName.trim();
    if (name.isEmpty) return;

    final next = List<String>.from(project.classes)..[index] = name;
    final updated = await appUseCases.project.updateClasses(project.id, next);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  Future<void> removeClass(int index) async {
    if (index < 0 || index >= project.classes.length) return;

    final next = List<String>.from(project.classes)..removeAt(index);
    final updated = await appUseCases.project.updateClasses(project.id, next);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  // ==============================
  // 📂 데이터 추가/제거
  // ==============================

  /// 단일 데이터 추가 (파일 선택 로직은 외부/VM 상단에서 수행했다고 가정)
  Future<void> addDataInfo(DataInfo dataInfo) async {
    final updated = await appUseCases.project.addDataInfo(project.id, dataInfo);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  /// dataId 기준으로 제거
  Future<void> removeDataInfo(String dataId) async {
    final updated = await appUseCases.project.removeDataInfo(project.id, dataId);
    if (updated != null) {
      project = updated;
      notifyListeners();
      onChanged?.call(project);
    }
  }

  // ==============================
  // 📌 변경 감지
  // ==============================

  bool isLabelingModeChanged() => project.mode != _initialMode;

  // ==============================
  // 💾 저장 / 삭제 / 초기화
  // ==============================

  /// 현재 스냅샷 저장(업서트)
  Future<void> saveProject() async {
    await appUseCases.project.save(project);
    notifyListeners();
    onChanged?.call(project);
  }

  /// 프로젝트의 모든 라벨 삭제
  Future<void> clearProjectLabels() async {
    await appUseCases.label.clearAll(project.id);
    notifyListeners();
    onChanged?.call(project);
  }

  void updateFrom(Project updated) {
    project = updated;
    notifyListeners();
  }

  // ==============================
  // ⬇️ 다운로드 & 공유
  // ==============================

  Future<void> downloadProjectConfig() async {
    try {
      await appUseCases.project.exportConfig(project);
    } catch (e) {
      debugPrint("❌ Failed to download config: $e");
    }
  }

  /// 구성 JSON(혹은 링크)을 공유
  Future<void> shareProject(BuildContext context) async {
    try {
      final pathOrUrl = await appUseCases.project.exportConfig(project);
      // ShareHelper가 파일/텍스트 중 무엇을 지원하는지에 따라 분기
      // 아래는 간단히 텍스트 공유로 처리(필요시 shareFile로 교체)
      await shareHelper.shareText(pathOrUrl);
      if (context.mounted) {
        GlobalAlertManager.show(context, '✅ 프로젝트 공유 준비가 완료되었습니다.', type: AlertType.success);
      }
    } catch (e) {
      if (context.mounted) {
        GlobalAlertManager.show(context, '⚠️ 프로젝트 공유에 실패했습니다: $e', type: AlertType.error);
      }
    }
  }
}
