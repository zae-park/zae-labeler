// lib/src/features/project/providers/project_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/models/data/data_info.dart';
import '../../../core/models/label/label_model.dart' show LabelingMode;
import '../../../core/models/project/project_model.dart';
import '../../label/use_cases/label_use_cases.dart' show LabelingSummary;
import '../use_cases/edit_project_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 프로젝트 목록
// ─────────────────────────────────────────────────────────────────────────────

/// 저장소의 프로젝트 목록. 스토리지가 바뀌면([storageRevisionProvider]) 자동으로 다시 읽습니다.
class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() {
    ref.watch(storageRevisionProvider);
    return ref.watch(projectUseCasesProvider).fetchAll();
  }

  List<Project> get _current => state.value ?? const [];

  /// 저장소에서 다시 읽습니다.
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  /// 메모리 목록만 갱신합니다(이미 저장된 프로젝트를 반영할 때).
  void syncLocal(Project project) {
    final list = [..._current];
    final i = list.indexWhere((p) => p.id == project.id);
    i < 0 ? list.add(project) : list[i] = project;
    state = AsyncData(List.unmodifiable(list));
  }

  /// 추가 또는 갱신 후 목록 전체를 저장합니다.
  Future<void> upsert(Project project) async {
    syncLocal(project);
    await ref.read(projectUseCasesProvider).saveAll(_current);
    ref.invalidate(projectSummaryProvider(project.id));
  }

  /// 프로젝트와 라벨을 모두 삭제합니다.
  Future<void> remove(String projectId) async {
    await ref.read(projectUseCasesProvider).deleteProjectFully(projectId);
    state = AsyncData(List.unmodifiable(_current.where((p) => p.id != projectId)));
    ref.invalidate(projectSummaryProvider(projectId));
  }

  /// 설정 파일을 내보내고 경로/URL을 돌려줍니다.
  Future<String> exportConfig(Project project) => ref.read(projectUseCasesProvider).exportConfig(project);

  /// 설정을 내보낸 뒤 공유 시트를 엽니다.
  Future<void> share(Project project) async {
    final pathOrUrl = await exportConfig(project);
    await ref.read(shareHelperProvider).shareText(pathOrUrl);
  }
}

final projectListProvider = AsyncNotifierProvider<ProjectListNotifier, List<Project>>(ProjectListNotifier.new);

/// 프로젝트별 라벨링 진행률 요약. 실패하면 빈 요약을 돌려줍니다.
/// 전체 새로고침은 `ref.invalidate(projectSummaryProvider)`.
final projectSummaryProvider = FutureProvider.family<LabelingSummary, String>((ref, projectId) async {
  ref.watch(storageRevisionProvider);
  try {
    return await ref.watch(labelUseCasesProvider).computeSummary(projectId);
  } catch (e) {
    debugPrint('❌ Failed to fetch summary for project $projectId: $e');
    return LabelingSummary.empty();
  }
}, retry: (_, __) => null);

// ─────────────────────────────────────────────────────────────────────────────
// 프로젝트 편집기
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ProjectEditorState {
  final Project project;

  /// 기존 프로젝트 편집이면 true, 새로 만드는 중이면 false.
  final bool isEditing;
  final bool isBusy;

  const ProjectEditorState({required this.project, required this.isEditing, this.isBusy = false});

  ProjectEditorState copyWith({Project? project, bool? isBusy}) =>
      ProjectEditorState(project: project ?? this.project, isEditing: isEditing, isBusy: isBusy ?? this.isBusy);
}

/// 프로젝트 생성/편집 화면 상태. 인자로 편집할 프로젝트(신규면 null)를 받습니다.
///
/// 각 편집은 `EditProjectUseCase`가 검증·저장한 새 스냅샷으로 상태를 교체하고, 목록에도 즉시 반영합니다.
/// 화면을 벗어나면 autoDispose로 정리됩니다.
class ProjectEditorNotifier extends Notifier<ProjectEditorState> {
  ProjectEditorNotifier(this.initial);

  final Project? initial;

  @override
  ProjectEditorState build() => ProjectEditorState(
    project: initial ?? Project(id: const Uuid().v4(), name: 'New Project', mode: LabelingMode.singleClassification, classes: const ['True', 'False']),
    isEditing: initial != null,
  );

  Future<void> _apply(Future<Project> Function(Project current) edit) async {
    final updated = await edit(state.project);
    if (!ref.mounted) return;
    state = state.copyWith(project: updated);
    ref.read(projectListProvider.notifier).syncLocal(updated);
  }

  EditProjectUseCase get _editor => ref.read(projectUseCasesProvider).editor;

  Future<void> setName(String name) => _apply((p) => _editor.rename(p, name));

  /// 모드를 바꾸면 기존 라벨은 삭제됩니다(EditProjectUseCase 기본 정책).
  Future<void> setLabelingMode(LabelingMode mode) async {
    if (state.project.mode == mode) return;
    await _apply((p) => _editor.changeMode(p, mode));
  }

  Future<void> addClass(String className) async {
    final name = className.trim();
    if (name.isEmpty) return;
    await _apply((p) => _editor.addClass(p, name));
  }

  Future<void> editClass(int index, String newName) => _apply((p) => _editor.editClass(p, index, newName));

  Future<void> removeClass(int index) => _apply((p) => _editor.removeClass(p, index));

  Future<void> addDataInfos(List<DataInfo> infos) async {
    if (infos.isEmpty) return;
    await _apply((p) => _editor.addDataInfos(p, infos));
  }

  Future<void> removeDataInfoAt(int index) async {
    final infos = state.project.dataInfos;
    if (index < 0 || index >= infos.length) return;
    final id = infos[index].id;
    await _apply((p) => _editor.removeDataInfoById(p, id));
  }

  /// 파일 선택기로 데이터를 고르고 추가합니다. 진행 중에는 [ProjectEditorState.isBusy].
  Future<void> pickAndAddDataInfos() async {
    state = state.copyWith(isBusy: true);
    try {
      final infos = await ref.read(dataInfoPickerProvider).pick();
      if (infos.isEmpty) {
        debugPrint('⚠️ picker returned empty. check factory wiring / upload / permissions');
        return;
      }
      await addDataInfos(infos);
    } catch (e, st) {
      debugPrint('❌ pickAndAddDataInfos error: $e\n$st');
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// 확정: 목록에 반영하고 목록 전체를 저장합니다.
  Future<Project> confirm() async {
    final project = state.project;
    await ref.read(projectListProvider.notifier).upsert(project);
    return project;
  }
}

final projectEditorProvider = NotifierProvider.autoDispose.family<ProjectEditorNotifier, ProjectEditorState, Project?>(ProjectEditorNotifier.new);
