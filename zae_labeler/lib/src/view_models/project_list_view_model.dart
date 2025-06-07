import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../domain/project/project_use_cases.dart';

/// 🔧 ViewModel: 전체 프로젝트 리스트를 관리
/// - 저장소로부터 프로젝트를 불러오고, 상태를 관리하며 View와 연결됨
/// ProjectListViewModel
/// ├── loadProjects()               // 저장소에서 전체 프로젝트 목록을 불러옴
/// ├── saveProject(Project)         // 기존 리스트에 있으면 갱신, 없으면 추가
/// ├── updateProject(Project)       // 리스트 내 기존 항목을 외부 변경 사항으로 덮어쓰기
/// ├── removeProject(String)        // ID 기준으로 삭제 및 리스트 재로드
/// └── clearAllProjectsCache()      // 캐시 비우고 리스트 초기화

class ProjectListViewModel extends ChangeNotifier {
  final ProjectUseCases useCases;

  List<Project> _projects = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Project> get projects => _projects;

  ProjectListViewModel({required this.useCases}) {
    loadProjects();
  }

  /// ✅ 전체 프로젝트 불러오기
  /// - 로딩 상태 관리 포함
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await useCases.io.fetchAll();

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 프로젝트 저장 (추가 또는 갱신)
  /// - 동일 ID가 존재하면 속성만 갱신
  Future<void> saveProject(Project project) async {
    debugPrint("[ProjectListVM] 💾 saveProject 호출됨: \${project.id}, \${project.name}");

    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      final updated = _projects[index].copyWith(
        name: project.name,
        mode: project.mode,
        classes: project.classes,
        dataInfos: project.dataInfos,
      );
      _projects[index] = updated;
    } else {
      _projects.add(project);
    }

    await useCases.io.saveAll(_projects);
    notifyListeners();
  }

  /// ✅ 프로젝트 삭제
  /// - 저장소에서도 삭제 후, 전체 목록을 다시 로드
  Future<void> removeProject(String projectId) async {
    await useCases.io.deleteById(projectId);
    await loadProjects(); // 내부적으로 notifyListeners 호출
  }

  /// ✅ 프로젝트 강제 업데이트
  /// - 외부에서 전체 변경된 값을 반영하고 싶을 때 사용
  /// - 일반적으로는 saveProject로 통합 가능
  Future<void> updateProject(Project updatedProject) async {
    debugPrint("[ProjectListVM] 💾 updateProject 호출됨: \${updatedProject.id}, \${updatedProject.name}");

    final index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await useCases.io.saveAll(_projects);
      debugPrint("[ProjectListVM] 💾 Project Updated");
      notifyListeners();
    }
  }

  /// ✅ 프로젝트 캐시 비우기
  Future<void> clearAllProjectsCache() async {
    await useCases.io.clearCache();
    _projects.clear();
    notifyListeners();
  }
}
