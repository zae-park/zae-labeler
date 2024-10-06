// lib/src/view_models/project_manager.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:uuid';

class ProjectManager extends ChangeNotifier {
  List<Project> _projects = [];

  List<Project> get projects => _projects;

  ProjectManager() {
    // 초기화 시 프로젝트 로드
    loadProjects();
  }

  // 프로젝트 로드
  Future<void> loadProjects() async {
    _projects = await StorageHelper.loadProjects();
    notifyListeners();
  }

  // 새 프로젝트 생성
  Future<void> createProject(
      String name, LabelingMode mode, List<String> classes) async {
    final newProject = Project(
      id: Uuid().v4(),
      name: name,
      mode: mode,
      classes: classes,
    );
    _projects.add(newProject);
    await StorageHelper.saveProjects(_projects);
    notifyListeners();
  }

  // 기존 프로젝트 추가 등 필요한 메서드 추가 가능
}
