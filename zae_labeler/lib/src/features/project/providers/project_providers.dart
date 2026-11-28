// lib/src/features/project/providers/project_providers.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/models/data/data_info.dart';
import '../../../core/models/label/label_model.dart' show LabelingMode;
import '../../../core/models/project/project_model.dart';
import '../../label/use_cases/label_use_cases.dart' show LabelingSummary;
import '../logic/project_validator.dart';
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
/// - 목록에 이미 있는 [Project]를 사용하므로 프로젝트마다 목록 전체를 다시 읽지 않습니다(라벨만 조회).
/// - 전체 새로고침은 `ref.invalidate(projectSummaryProvider)`.
final projectSummaryProvider = FutureProvider.family<LabelingSummary, String>((ref, projectId) async {
  ref.watch(storageRevisionProvider);
  final labels = ref.watch(labelUseCasesProvider);
  try {
    final projects = await ref.read(projectListProvider.future);
    final project = projects.where((p) => p.id == projectId).firstOrNull;
    return project == null ? await labels.computeSummary(projectId) : await labels.computeSummaryByProject(project);
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

  /// 마지막 편집이 검증/저장에 실패한 이유(성공하면 null).
  final String? error;

  const ProjectEditorState({required this.project, required this.isEditing, this.isBusy = false, this.error});

  ProjectEditorState copyWith({Project? project, bool? isBusy, String? error, bool clearError = false}) => ProjectEditorState(
    project: project ?? this.project,
    isEditing: isEditing,
    isBusy: isBusy ?? this.isBusy,
    error: clearError ? null : (error ?? this.error),
  );
}

/// 프로젝트 생성/편집 화면 상태. 인자로 편집할 프로젝트(신규면 null)를 받습니다.
///
/// 각 편집은 `EditProjectUseCase`가 검증·저장한 새 스냅샷으로 상태를 교체하고, 목록에도 즉시 반영합니다.
/// 화면을 벗어나면 autoDispose로 정리됩니다.
class ProjectEditorNotifier extends Notifier<ProjectEditorState> {
  ProjectEditorNotifier(this.initial);

  final Project? initial;

  /// 이름 입력은 키 입력마다 저장하지 않고, 입력이 멈춘 뒤 한 번 저장합니다.
  static Duration renameDebounce = const Duration(milliseconds: 400);

  Timer? _renameTimer;
  String? _pendingName;

  /// dispose 시점에는 state를 읽을 수 없으므로 마지막 스냅샷을 따로 보관합니다.
  late Project _latest;

  @override
  ProjectEditorState build() {
    // 화면을 닫을 때 아직 저장되지 않은 이름이 있으면 마저 저장합니다.
    final editor = ref.read(projectUseCasesProvider).editor;
    final list = ref.read(projectListProvider.notifier);
    ref.onDispose(() {
      _renameTimer?.cancel();
      final name = _pendingName;
      if (name == null) return;
      _pendingName = null;
      unawaited(editor.rename(_latest, name).then(list.syncLocal, onError: (Object e) => debugPrint('❌ rename on dispose failed: $e')));
    });

    _latest = initial ?? Project(id: const Uuid().v4(), name: 'New Project', mode: LabelingMode.singleClassification, classes: const ['True', 'False']);
    return ProjectEditorState(project: _latest, isEditing: initial != null);
  }

  void _setProject(Project project) {
    _latest = project;
    state = state.copyWith(project: project);
  }

  /// 편집을 적용합니다. 검증/저장에 실패하면 예외를 던지지 않고 [ProjectEditorState.error]에 남기고 false를 돌려줍니다.
  /// (UI 콜백·타이머에서 호출되므로 예외가 처리되지 않은 채 흩어지지 않게 합니다.)
  Future<bool> _apply(Future<Project> Function(Project current) edit) async {
    try {
      final updated = await edit(state.project);
      if (!ref.mounted) return true;
      _latest = updated;
      state = state.copyWith(project: updated, clearError: true);
      ref.read(projectListProvider.notifier).syncLocal(updated);
      return true;
    } catch (e) {
      debugPrint('❌ project edit failed: $e');
      if (ref.mounted) state = state.copyWith(error: _messageOf(e));
      return false;
    }
  }

  static String _messageOf(Object e) => e is ArgumentError ? '${e.message}' : '$e';

  EditProjectUseCase get _editor => ref.read(projectUseCasesProvider).editor;

  /// 화면에는 즉시 반영하고, 저장은 [renameDebounce] 뒤 한 번만 합니다.
  void setName(String name) {
    _setProject(state.project.copyWith(name: name));
    _pendingName = name;
    _renameTimer?.cancel();
    _renameTimer = Timer(renameDebounce, flushPendingName);
  }

  /// 대기 중인 이름 변경을 지금 저장합니다. 성공(또는 대기 없음)이면 true.
  Future<bool> flushPendingName() async {
    _renameTimer?.cancel();
    final name = _pendingName;
    if (name == null) return true;
    _pendingName = null;
    return _apply((p) => _editor.rename(p, name));
  }

  /// 모드를 바꾸면 기존 라벨은 삭제됩니다(EditProjectUseCase 기본 정책).
  Future<bool> setLabelingMode(LabelingMode mode) async {
    if (state.project.mode == mode) return true;
    return _apply((p) => _editor.changeMode(p, mode));
  }

  Future<bool> addClass(String className) async {
    final name = className.trim();
    if (name.isEmpty) return true;
    return _apply((p) => _editor.addClass(p, name));
  }

  Future<bool> editClass(int index, String newName) => _apply((p) => _editor.editClass(p, index, newName));

  Future<bool> removeClass(int index) => _apply((p) => _editor.removeClass(p, index));

  Future<bool> addDataInfos(List<DataInfo> infos) async {
    if (infos.isEmpty) return true;
    return _apply((p) => _editor.addDataInfos(p, infos));
  }

  Future<bool> removeDataInfoAt(int index) async {
    final infos = state.project.dataInfos;
    if (index < 0 || index >= infos.length) return true;
    final id = infos[index].id;
    return _apply((p) => _editor.removeDataInfoById(p, id));
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
  /// 검증에 실패하면 저장하지 않고 null을 돌려줍니다(이유는 [ProjectEditorState.error]).
  Future<Project?> confirm() async {
    if (!await flushPendingName()) return null;
    final project = state.project;
    try {
      ProjectValidator.validate(project);
    } catch (e) {
      state = state.copyWith(error: _messageOf(e));
      return null;
    }
    await ref.read(projectListProvider.notifier).upsert(project);
    return project;
  }
}

final projectEditorProvider = NotifierProvider.autoDispose.family<ProjectEditorNotifier, ProjectEditorState, Project?>(ProjectEditorNotifier.new);
