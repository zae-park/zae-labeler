// lib/src/view_models/project_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';

class ProjectViewModel extends ChangeNotifier {
  List<Project> _projects = [];

  ProjectViewModel() {
    loadProjects();
  }

  List<Project> get projects => _projects;

  Future<void> loadProjects() async {
    _projects = await StorageHelper.instance.loadProjects(); // 싱글톤 인스턴스를 통해 접근
    notifyListeners();
  }

  Future<void> saveProject(Project project) async {
    _projects.add(project);
    await StorageHelper.instance.saveProjects(_projects); // 싱글톤 인스턴스를 통해 접근
    notifyListeners();
  }

  Future<void> removeProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);
    await StorageHelper.instance.saveProjects(_projects); // 싱글톤 인스턴스를 통해 접근
    notifyListeners();
  }

  Future<void> updateProject(Project updatedProject) async {
    int index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await StorageHelper.instance.saveProjects(_projects); // 싱글톤 인스턴스를 통해 접근
      notifyListeners();
    }
  }

  Future<void> loadProjectData(Project project) async {
    if (project.isDataLoaded) return; // 이미 로드된 경우 무시

    try {
      // 데이터 로드 시작
      project.isDataLoaded = false;
      notifyListeners();

      // Project의 데이터 로드 기능 호출
      final labelEntries = await project.loadLabelEntries();

      // 로드 완료 플래그 설정
      project.isDataLoaded = true;
      notifyListeners();

      print('Project data loaded with ${labelEntries.length} entries.');
    } catch (e) {
      print('Error loading project data: $e');
    }
  }
}
