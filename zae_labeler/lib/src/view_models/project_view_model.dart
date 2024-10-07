// lib/src/view_models/project_view_model.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';

class ProjectViewModel extends ChangeNotifier {
  List<Project> _projects = [];

  ProjectViewModel() {
    loadProjects();
  }

  List<Project> get projects => _projects;

  Future<void> loadProjects() async {
    _projects = await StorageHelper.loadProjects();
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    _projects.add(project);
    await StorageHelper.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> removeProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);
    await StorageHelper.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> updateProject(Project updatedProject) async {
    int index =
        _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await StorageHelper.saveProjects(_projects);
      notifyListeners();
    }
  }
}
