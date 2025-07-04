import 'package:flutter/material.dart';
import '../../../core/models/project_model.dart';
import '../use_cases/project_use_cases.dart';
import '../../../platform_helpers/share/get_helper.dart';
import 'project_view_model.dart';

/// 🔧 ViewModel: 전체 프로젝트 리스트를 관리
/// - 저장소로부터 프로젝트를 불러오고, 상태를 관리하며 View와 연결됨
/// ProjectListViewModel
/// ├── loadProjects()               // 저장소에서 전체 프로젝트 목록을 불러옴
/// ├── upsertProject(Project)       // 프로젝트 추가 또는 갱신
/// ├── removeProject(String)        // ID 기준으로 삭제 및 리스트 재로드
/// └── clearAllProjectsCache()      // 캐시 비우고 리스트 초기화

class ProjectListViewModel extends ChangeNotifier {
  final ProjectUseCases projectUseCases;

  final Map<String, ProjectViewModel> _projectVMs = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<ProjectViewModel> get projectVMList => _projectVMs.values.toList();

  ProjectListViewModel({required this.projectUseCases}) {
    loadProjects();
  }

  /// ✅ 개별 ProjectViewModel 접근
  ProjectViewModel? getVMById(String id) => _projectVMs[id];

  /// ✅ 전체 프로젝트 불러오기
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    final loadedProjects = await projectUseCases.io.fetchAll();
    _projectVMs
      ..clear()
      ..addEntries(loadedProjects.map((p) => MapEntry(
            p.id,
            ProjectViewModel(project: p, useCases: projectUseCases, shareHelper: getShareHelper(), onChanged: (updated) => upsertProject(updated)),
          )));

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
        project: project,
        useCases: projectUseCases,
        shareHelper: getShareHelper(),
        onChanged: (updated) => upsertProject(updated),
      );
    }
    await projectUseCases.io.saveAll(_projectVMs.values.map((vm) => vm.project).toList());
    notifyListeners();
  }

  /// ✅ 프로젝트 삭제
  /// - 저장소에서도 삭제 후, 전체 목록을 다시 로드
  Future<void> removeProject(String projectId) async {
    await projectUseCases.io.deleteById(projectId);
    await loadProjects(); // 내부적으로 notifyListeners 호출
  }

  /// ✅ 프로젝트 캐시 비우기
  Future<void> clearAllProjectsCache() async {
    await projectUseCases.io.clearCache();
    _projectVMs.clear();
    notifyListeners();
  }
}
