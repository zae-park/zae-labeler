// lib/src/view_models/project_manager_view_model.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'package:uuid/uuid.dart'; // 올바른 import 경로

class ProjectManagerViewModel extends ChangeNotifier {
  List<Project> _projects = [];
  final Uuid _uuid = const Uuid(); // Uuid 인스턴스 생성

  List<Project> get projects => _projects;

  ProjectManagerViewModel() {
    // 초기화 시 프로젝트 로드
    loadProjects();
  }

  // 프로젝트 로드
  Future<void> loadProjects() async {
    _projects = await StorageHelper.loadProjects();
    notifyListeners();
  }

  // 새 프로젝트 생성
  Future<void> createProject(String name, LabelingMode mode,
      List<String> classes, String dataDirectory) async {
    final newProject = Project(
      id: _uuid.v4(), // Uuid 사용
      name: name,
      mode: mode,
      classes: classes,
      dataDirectory: dataDirectory,
    );
    _projects.add(newProject);
    await StorageHelper.saveProjects(_projects);
    notifyListeners();
  }

  // 기존 프로젝트 추가 등 필요한 메서드 추가 가능
}
