import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';

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
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await repository.fetchAllProjects();
    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 프로젝트 저장 (mode/class 변경 반영 포함)
  Future<void> saveProject(Project project) async {
    debugPrint("[ProjectListVM] 💾 saveProject 호출됨: ${project.id}, ${project.name}");

    final existing = _projects.where((p) => p.id == project.id).firstOrNull;
    if (existing != null) {
      // 기존 프로젝트에 값 복사
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
  Future<void> removeProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await repository.saveAll(_projects);
    notifyListeners();
  }

  /// ✅ 프로젝트 강제 업데이트 (외부에서 설정 전체 덮어쓰기)
  Future<void> updateProject(Project updatedProject) async {
    debugPrint("[ProjectListVM] 💾 updateProject 호출됨: ${updatedProject.id}, ${updatedProject.name}");

    int index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await repository.saveAll(_projects);
      debugPrint("[ProjectListVM] 💾 Project Updated");
      notifyListeners();
    }
  }

  /// ✅ 모든 프로젝트 데이터 캐시 초기화
  Future<void> clearAllProjectsCache() async {
    await repository.storageHelper.clearAllCache();
    _projects.clear();
    notifyListeners();
  }
}
