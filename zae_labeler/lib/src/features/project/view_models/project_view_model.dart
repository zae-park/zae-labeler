// lib/src/features/project/view_models/project_view_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:zae_labeler/common/widgets/global_alert.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';

import '../../../core/models/data/data_info.dart';
import '../../../core/models/label/label_model.dart' show LabelingMode; // 임시: 모드 여기 위치
import '../../../core/models/project/project_model.dart';

import '../../../platform_helpers/pickers/data_info_picker_interface.dart';
import '../../../platform_helpers/share/interface_share_helper.dart';

/// {@template project_view_model}
/// 🔧 ProjectViewModel
///
/// 단일 프로젝트 화면의 **상태와 액션**을 보유하는 MVVM ViewModel.
///
/// ### 책임 분리
/// - **쓰기(편집)**: `EditProjectUseCase`에 위임합니다.
///   - 이름/모드/클래스/데이터 편집 등은 `appUseCases.project.edit`를 호출하여
///     **새 Project 스냅샷**을 돌려받아 `project` 필드를 교체합니다.
/// - **읽기/진행률**: 프로젝트 목록의 진행률 요약은 `ProjectListViewModel`이 `LabelUseCases`로 계산합니다.
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
  final DataInfoPicker picker;
  final ShareHelperInterface? shareHelper;
  final AppUseCases appUseCases;

  final void Function(Project updated)? onChanged;
  final bool isEditing;
  late LabelingMode _initialMode;
  bool _busy = false;
  bool get isBusy => _busy;

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  ProjectViewModel({required this.appUseCases, required this.picker, this.shareHelper, this.onChanged, Project? initial, bool? isEditing})
    : isEditing = isEditing ?? (initial != null),
      project = initial ?? Project(id: const Uuid().v4(), name: 'New Project', mode: LabelingMode.singleClassification, classes: const ["True", "False"]) {
    _initialMode = project.mode; // ✅ 내부에서 설정
  }

  // ==============================
  // ✏️ 프로젝트 편집 (EditProjectUseCase 위임)
  // ==============================
  Future<void> setName(String name) async {
    final updated = await appUseCases.project.editor.rename(project, name);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> setLabelingMode(LabelingMode mode) async {
    if (project.mode == mode) return;
    final updated = await appUseCases.project.editor.changeMode(project, mode);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> addClass(String className) async {
    final name = className.trim();
    if (name.isEmpty) return;
    final updated = await appUseCases.project.editor.addClass(project, name);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> editClass(int index, String newName) async {
    final updated = await appUseCases.project.editor.editClass(project, index, newName);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> removeClass(int index) async {
    final updated = await appUseCases.project.editor.removeClass(project, index);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> pickAndAddDataInfos() async {
    _setBusy(true);
    try {
      debugPrint('[VM.pick] start');
      final infos = await picker.pick();
      debugPrint('[VM.pick] picked=${infos.length}');
      if (infos.isEmpty) {
        debugPrint('⚠️ picker returned empty. check factory wiring / upload / permissions');
        return;
      }
      final before = project.dataInfos.length;
      final updated = await appUseCases.project.editor.addDataInfos(project, infos);
      project = updated;
      debugPrint('[VM.pick] applied: before=$before, after=${project.dataInfos.length}');
      onChanged?.call(project);
      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ pickAndAddDataInfos error: $e\n$st');
      // 필요하면 토스트/다이얼로그
    } finally {
      _setBusy(false);
    }
  }

  Future<void> addDataInfos(List<DataInfo> infos) async {
    if (infos.isEmpty) return;
    final updated = await appUseCases.project.editor.addDataInfos(project, infos);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> addDataInfo(DataInfo info) async {
    final updated = await appUseCases.project.editor.addDataInfo(project, info);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  /// 권장: id 기반 제거
  Future<void> removeDataInfoAt(int index) async {
    if (index < 0 || index >= project.dataInfos.length) return;
    final dataId = project.dataInfos[index].id;
    final updated = await appUseCases.project.editor.removeDataInfoById(project, dataId);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> setAllDataInfos(List<DataInfo> infos) async {
    final updated = await appUseCases.project.editor.setDataInfos(project, infos);
    project = updated;
    onChanged?.call(project);
    notifyListeners();
  }

  bool isLabelingModeChanged() => project.mode != _initialMode;

  // ==============================
  // 💾 저장 / 삭제 / 초기화 (기존 파사드 기능)
  // ==============================
  Future<void> saveProject() async {
    await appUseCases.project.save(project);
    onChanged?.call(project);
    notifyListeners();
  }

  Future<void> clearProjectLabels() async {
    await appUseCases.label.clearAll(project.id);
    onChanged?.call(project);
    notifyListeners();
  }

  void updateFrom(Project updated) {
    project = updated;
    notifyListeners();
  }

  /// ✅ reset 동작: 편집이면 복제(변경 취소), 신규면 새 스냅샷로 초기화
  void reset() {
    if (isEditing) {
      project = project.copyWith(); // 원본 유지 + 임시 변경만 초기화 효과(필요시 별도 원본 보관)
    } else {
      project = Project(id: const Uuid().v4(), name: '', mode: LabelingMode.singleClassification, classes: const []);
    }
    _initialMode = project.mode;
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

  Future<void> shareProject(BuildContext context) async {
    if (shareHelper == null) {
      if (context.mounted) GlobalAlertManager.show(context, '⚠️ 공유 도구가 설정되어 있지 않습니다.', type: AlertType.error);
      return;
    }

    try {
      final pathOrUrl = await appUseCases.project.exportConfig(project);
      await shareHelper!.shareText(pathOrUrl);
      if (context.mounted) GlobalAlertManager.show(context, '✅ 프로젝트 공유 준비가 완료되었습니다.', type: AlertType.success);
    } catch (e) {
      if (context.mounted) GlobalAlertManager.show(context, '⚠️ 프로젝트 공유에 실패했습니다: $e', type: AlertType.error);
    }
  }
}
