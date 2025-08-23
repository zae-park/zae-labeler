// lib/src/features/project/view_models/project_list_view_model.dart
import 'package:flutter/material.dart';

import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart' show LabelingSummary;
import 'package:zae_labeler/src/platform_helpers/pickers/data_info_picker_interface.dart';
import 'package:zae_labeler/src/platform_helpers/share/interface_share_helper.dart';

import '../../../core/models/project/project_model.dart';
import 'project_view_model.dart';

/// 🔧 ViewModel: 전체 프로젝트 리스트를 관리
/// - 저장소로부터 프로젝트를 불러오고, 각 프로젝트별 VM을 생성/보관
/// - 프로젝트 추가/갱신/삭제, 전체 비우기, 프로젝트별 라벨 요약 캐싱
class ProjectListViewModel extends ChangeNotifier {
  final AppUseCases appUseCases;
  final ShareHelperInterface shareHelper;
  final DataInfoPicker picker;

  final Map<String, ProjectViewModel> _projectVMs = {};
  final Map<String, LabelingSummary?> _summaries = {};
  final Set<String> _requestedSummaryIds = {};

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<ProjectViewModel> get projectVMList => _projectVMs.values.toList(growable: false);
  Map<String, LabelingSummary?> get summaries => _summaries;

  ProjectListViewModel({required this.appUseCases, required this.shareHelper, required this.picker}) {
    loadProjects();
  }

  /// 개별 ProjectViewModel 접근
  ProjectViewModel? getVMById(String id) => _projectVMs[id];

  /// ✅ 전체 프로젝트 불러오기
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    final loadedProjects = await appUseCases.project.fetchAll();

    _projectVMs
      ..clear()
      ..addEntries(
        loadedProjects.map(
          (p) => MapEntry(
            p.id,
            ProjectViewModel(
              initial: p,
              isEditing: true, // ✅ 기존 프로젝트이므로 편집 모드
              appUseCases: appUseCases,
              picker: picker, // ✅ 필수 주입
              shareHelper: shareHelper,
              onChanged: (updated) => upsertProject(updated),
            ),
          ),
        ),
      );

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 프로젝트 추가 또는 갱신 (Upsert)
  /// - 동일 ID가 존재하면 갱신, 없으면 추가
  Future<void> upsertProject(Project project) async {
    if (_projectVMs.containsKey(project.id)) {
      _projectVMs[project.id]!.updateFrom(project);
    } else {
      _projectVMs[project.id] = ProjectViewModel(
        initial: project,
        isEditing: true, // ✅ 리스트에 들어온 시점부터는 편집
        appUseCases: appUseCases,
        picker: picker, // ✅ 필수 주입
        shareHelper: shareHelper,
        onChanged: (updated) => upsertProject(updated),
      );
    }

    // 리스트 스냅샷을 저장 (필요 시 성능 고려해 배치 타이머/디바운스 적용)
    await appUseCases.project.saveAll(_projectVMs.values.map((vm) => vm.project).toList());
    notifyListeners();
  }

  /// ✅ 프로젝트 삭제
  /// - 저장소에서도 삭제 후, 전체 목록을 다시 로드
  Future<void> removeProject(String projectId) async {
    await appUseCases.project.deleteProjectFully(projectId);
    await loadProjects(); // 내부적으로 notifyListeners 호출
  }

  /// ✅ 모든 프로젝트 비우기(캐시/로컬 저장소)
  Future<void> clearAllProjectsCache() async {
    await appUseCases.project.deleteAll(); // 또는 saveAll([])
    _projectVMs.clear();
    notifyListeners();
  }

  /// ✅ 라벨 요약(진행률/통계) 가져오기 + 캐시
  Future<void> fetchSummary(String projectId, {bool force = false}) async {
    if (!force && _requestedSummaryIds.contains(projectId)) return;
    _requestedSummaryIds.add(projectId);

    _summaries[projectId] = null;
    notifyListeners();

    try {
      final project = _projectVMs[projectId]?.project;
      if (project == null) return;

      // Label 파사드에서 요약 계산 API를 노출한다고 가정
      final summary = await appUseCases.label.computeSummary(projectId);
      _summaries[projectId] = summary;
    } catch (e) {
      debugPrint("❌ Failed to fetch summary for project $projectId: $e");
      _summaries[projectId] = LabelingSummary.empty();
    }

    notifyListeners();
  }

  ProjectViewModel createNewProjectVM() {
    return ProjectViewModel(
      appUseCases: appUseCases,
      picker: picker,
      shareHelper: shareHelper,
      isEditing: false, // ✅ 신규
      onChanged: (updated) => upsertProject(updated),
    );
  }

  /// 요약 캐시 초기화
  void clearSummaries() {
    _summaries.clear();
    _requestedSummaryIds.clear();
    notifyListeners();
  }
}
