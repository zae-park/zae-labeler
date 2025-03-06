import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';

class ProjectListViewModel extends ChangeNotifier {
  final StorageHelperInterface storageHelper;

  List<Project> _projects = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Project> get projects => _projects;

  ProjectListViewModel({required this.storageHelper}) {
    loadProjects();
  }

  /// ✅ 모든 프로젝트 불러오기
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await storageHelper.loadProjectList();
    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 프로젝트 저장
  Future<void> saveProject(Project project) async {
    _projects.add(project);
    await storageHelper.saveProjectList(_projects);
    notifyListeners();
  }

  /// ✅ 프로젝트 삭제
  Future<void> removeProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await storageHelper.saveProjectList(_projects);
    notifyListeners();
  }

  /// ✅ 모든 프로젝트 데이터 캐시 초기화
  Future<void> clearAllProjectsCache() async {
    await storageHelper.clearAllCache();
    _projects.clear();
    notifyListeners();
  }
}



// import 'package:flutter/material.dart';
// import '../models/project_model.dart';
// import '../utils/storage_helper.dart';

// class ProjectListViewModel extends ChangeNotifier {
//   List<Project> _projects = [];

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   List<Project> get projects => _projects;

//   ProjectListViewModel() {
//     loadProjects();
//   }

//   /// ✅ 프로젝트 목록 불러오기 (StorageHelper에서 로드)
//   Future<void> loadProjects() async {
//     _isLoading = true;
//     notifyListeners();

//     _projects = await StorageHelper.instance.loadProjectFromConfig(""); // ✅ 기존 loadProjects() → loadProjectFromConfig() 변경

//     _isLoading = false;
//     notifyListeners();
//   }

//   /// ✅ 프로젝트 저장 (StorageHelper에 저장)
//   Future<void> saveProject(Project project) async {
//     _projects.add(project);
//     await StorageHelper.instance.saveProjectConfig(_projects); // ✅ 기존 saveProjects() → saveProjectConfig() 변경
//     notifyListeners();
//   }

//   /// ✅ 프로젝트 삭제
//   Future<void> removeProject(String projectId) async {
//     _projects.removeWhere((project) => project.id == projectId);
//     await StorageHelper.instance.saveProjectConfig(_projects); // ✅ 기존 saveProjects() → saveProjectConfig() 변경
//     notifyListeners();
//   }

//   /// ✅ 프로젝트 업데이트
//   Future<void> updateProject(BuildContext context, Project updatedProject) async {
//     int index = _projects.indexWhere((project) => project.id == updatedProject.id);
//     if (index != -1) {
//       _projects[index] = Project(
//         id: updatedProject.id,
//         name: updatedProject.name,
//         mode: updatedProject.mode,
//         classes: updatedProject.classes,
//         dataPaths: updatedProject.dataPaths,
//       );

//       await StorageHelper.instance.saveProjectConfig(_projects);

//       notifyListeners();
//     }
//   }
// }
