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

/// {@template project_view_model}
/// 🔧 ProjectViewModel
///
/// 단일 프로젝트 화면의 **상태와 액션**을 보유하는 MVVM ViewModel.
///
/// ### 책임 분리
/// - **쓰기(편집)**: `EditProjectUseCase`에 위임합니다.
///   - 이름/모드/클래스/데이터 편집 등은 `appUseCases.project.edit`를 호출하여
///     **새 Project 스냅샷**을 돌려받아 `project` 필드를 교체합니다.
/// - **읽기/진행률**: LabelingViewModelFactory로 진행률만 계산해 UI에 노출합니다.
/// - **저장/내보내기/공유**: 파사드(`ProjectUseCases`)의 IO/Export 계열을 사용합니다.
///
/// ### 기존 대비 변화
/// - 과거 VM 내부에서 직접 Repo를 호출하거나 attach-스타일로 부분 편집을 했던 흐름을,
///   이제는 **UseCase 단일 관문(EditProjectUseCase)**를 통해 일관되게 처리합니다.
/// - 메서드들은 대부분 “편집 → 유효성 검증 → 저장 → 새 스냅샷 반환” 순서를 UC에 맡기고,
///   VM은 **스냅샷 교체 + notify + onChanged 콜백**만 수행합니다.
///
/// ### 사용 예시
/// ```dart
/// final vm = ProjectViewModel(shareHelper: share, appUseCases: appUC, project: initial);
/// await vm.setName('새 이름');  // 내부적으로 editUseCase.rename 호출
/// await vm.addClass('cat');     // 내부적으로 editUseCase.addClass 호출
/// await vm.setLabelingMode(LabelingMode.multiClassification); // 모드 변경(+기존 라벨 초기화 전략은 UC/파사드에서 선택)
/// ```
/// {@endtemplate}
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
  // 📊 진행률 로딩 (읽기 전용)
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
  // ✏️ 프로젝트 편집 (EditProjectUseCase 위임)
  // ==============================

  /// 프로젝트 이름 변경
  Future<void> setName(String name) async {
    final updated = await appUseCases.project.editor.rename(project, name);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 라벨링 모드 변경
  ///
  /// - 기본 정책은 **모든 라벨 삭제 후 모드 교체**(EditProjectUC의 기본값)로 동작합니다.
  /// - 마이그레이션 전략이 필요하면, App/Processes 레이어에서
  ///   `changeMode(..., policy: migrateWithStrategy, migrate: ...)`를 감싼
  ///   헬퍼를 제공해 VM에서 그 메서드를 호출하는 식으로 확장하세요.
  Future<void> setLabelingMode(LabelingMode mode) async {
    if (project.mode == mode) return;
    // 여기서는 안전 기본값(라벨 삭제)으로 위임
    final updated = await appUseCases.project.editor.changeMode(project, mode);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 클래스 추가
  Future<void> addClass(String className) async {
    final name = className.trim();
    if (name.isEmpty) return;
    final updated = await appUseCases.project.editor.addClass(project, name);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 클래스 이름 수정
  Future<void> editClass(int index, String newName) async {
    final updated = await appUseCases.project.editor.editClass(project, index, newName);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 클래스 삭제
  Future<void> removeClass(int index) async {
    final updated = await appUseCases.project.editor.removeClass(project, index);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 데이터 여러 건 추가
  Future<void> addDataInfos(List<DataInfo> infos) async {
    if (infos.isEmpty) return;
    final updated = await appUseCases.project.editor.addDataInfos(project, infos);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 데이터 한 건 삭제(인덱스 기반)
  Future<void> removeDataInfoAt(int index) async {
    final updated = await appUseCases.project.editor.removeDataInfo(project, index);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  /// 데이터 세트 통째로 교체
  Future<void> setAllDataInfos(List<DataInfo> infos) async {
    final updated = await appUseCases.project.editor.setDataInfos(project, infos);
    project = updated;
    notifyListeners();
    onChanged?.call(project);
  }

  // ==============================
  // 📌 변경 감지
  // ==============================
  bool isLabelingModeChanged() => project.mode != _initialMode;

  // ==============================
  // 💾 저장 / 삭제 / 초기화 (기존 파사드 기능)
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

  /// 외부에서 주입된 최신 스냅샷으로 교체(네비게이션 결과 반영 등)
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

  /// 구성 JSON(혹은 링크) 공유
  Future<void> shareProject(BuildContext context) async {
    try {
      final pathOrUrl = await appUseCases.project.exportConfig(project);
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
