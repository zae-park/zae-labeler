import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';

/// 🔧 ViewModel: 전체 프로젝트 리스트를 관리
/// - 저장소로부터 프로젝트를 불러오고, 상태를 관리하며, View와 연결됨
class ProjectListViewModel extends ChangeNotifier {
  final ProjectRepository repository;

  List<Project> _projects = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Project> get projects => _projects;

  ProjectListViewModel({required this.repository}) {
    loadProjects();
  }

  /// ✅ 모든 프로젝트 불러오기
  /// - 로딩 상태를 관리하며 저장소에서 프로젝트 목록을 불러옴
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await repository.fetchAllProjects();

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 프로젝트 저장
  /// - 동일 ID가 있으면 덮어쓰고 없으면 추가
  /// - mode/class/dataInfo 등 변경도 즉시 반영
  Future<void> saveProject(Project project) async {
    debugPrint("[ProjectListVM] 💾 saveProject 호출됨: ${project.id}, ${project.name}");

    final existing = _projects.where((p) => p.id == project.id).firstOrNull;
    if (existing != null) {
      existing.name = project.name;
      existing.updateMode(project.mode);
      existing.updateClasses(project.classes);
      existing.updateDataInfos(project.dataInfos);
    } else {
      _projects.add(project);
    }

    await repository.saveAll(_projects);
    notifyListeners();
  }

  /// ✅ 프로젝트 삭제
  /// - 저장소에서 실제 삭제 후 전체 프로젝트를 새로 로드
  Future<void> removeProject(String projectId) async {
    await repository.deleteById(projectId);
    await loadProjects(); // 내부에서 notifyListeners 호출함
  }

  /// ✅ 프로젝트 덮어쓰기 (외부에서 전체 설정 변경 시 사용)
  Future<void> updateProject(Project updatedProject) async {
    debugPrint("[ProjectListVM] 💾 updateProject 호출됨: ${updatedProject.id}, ${updatedProject.name}");

    final index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await repository.saveAll(_projects);
      debugPrint("[ProjectListVM] 💾 Project Updated");
      notifyListeners();
    }
  }

  /// ✅ 프로젝트 캐시 초기화
  /// - 저장된 프로젝트 데이터 및 내부 리스트 초기화
  Future<void> clearAllProjectsCache() async {
    await repository.storageHelper.clearAllCache();
    _projects.clear();
    notifyListeners();
  }
}
