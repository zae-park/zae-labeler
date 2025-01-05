// lib/src/view_models/project_view_model.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
// import '../utils/platform_storage_helper.dart';

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

      if (kIsWeb && project.dataPaths != null) {
        // Web 환경: base64 데이터를 비동기로 디코딩하여 사용
        for (final data in project.dataPaths!) {
          final parts = data.split(':');
          if (parts.length == 2) {
            final fileName = parts[0];
            final fileData = base64Decode(parts[1]);
            // 파일 데이터 처리 로직 추가 (필요시 저장하거나 캐싱)
            print('Loaded $fileName with ${fileData.length} bytes');
          }
        }
      } else if (project.dataDirectory != null) {
        // Native 환경: 디렉토리에서 파일을 로드
        final directory = Directory(project.dataDirectory!);
        if (directory.existsSync()) {
          final files = directory.listSync();
          for (final file in files.whereType<File>()) {
            // 파일 데이터 처리 로직 추가
            print('Loaded file: ${file.path}');
          }
        }
      }

      // 데이터 로드 완료
      project.isDataLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading project data: $e');
    }
  }
}
