// lib/src/view_models/project_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';

class ProjectListViewModel extends ChangeNotifier {
  List<Project> _projects = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Project> get projects => _projects;

  ProjectListViewModel() {
    loadProjects();
  }

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners(); // ✅ UI 업데이트

    _projects = await StorageHelper.instance.loadProjects();
    List<Project> loadedProjects = await StorageHelper.instance.loadProjects(); // 비교를 위한 임시 변수 할당

    // ✅ 프로젝트 목록이 변경된 경우에만 UI 업데이트
    if (_projects.length != loadedProjects.length || !_listEquals(_projects, loadedProjects)) {
      _projects = loadedProjects;
      notifyListeners();
    }

    _isLoading = false;
    notifyListeners(); // ✅ 로딩 완료 후 UI 업데이트
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

  Future<void> updateProject(BuildContext context, Project updatedProject) async {
    int index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      Project existingProject = _projects[index];

      // ✅ LabelingMode 변경 시 경고창 표시
      if (existingProject.mode != updatedProject.mode) {
        bool confirmChange = await _showLabelingModeChangeDialog(context);
        if (!confirmChange) return; // 사용자가 취소하면 종료

        // 기존 라벨링 데이터 삭제 경고 후 작업 진행
        print("🛠 Labeling Mode 변경으로 이전 작업 내용이 삭제됩니다.");
        _clearLabelingData(updatedProject.mode);
      }

      // ✅ 새로운 Project 인스턴스를 생성하여 변경 적용
      _projects[index] = Project(
        id: updatedProject.id,
        name: updatedProject.name,
        mode: updatedProject.mode,
        classes: updatedProject.classes,
        dataPaths: updatedProject.dataPaths,
        labelEntries: updatedProject.labelEntries,
      );

      await StorageHelper.instance.saveProjects(_projects);

      print("📢 notifyListeners() 호출됨 - 프로젝트 변경 반영");
      notifyListeners(); // ✅ UI 즉시 업데이트
    }
  }

  /// ✅ 리스트 비교 함수 추가 (ID 기반 비교)
  bool _listEquals(List<Project> list1, List<Project> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  // 알림창 띄우는 메소드
  Future<bool> _showLabelingModeChangeDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Labeling Mode 변경 경고'),
              content: const Text('Labeling Mode를 변경하면 기존 작업 내용이 삭제됩니다. 변경하시겠습니까?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
              ],
            );
          },
        ) ??
        false;
  }

  void _clearLabelingData(LabelingMode newMode) {
    print("🗑 기존 라벨링 데이터 초기화: $newMode");
    // 새 모드에 맞게 기존 라벨링 데이터를 초기화
    if (newMode == LabelingMode.singleClassification || newMode == LabelingMode.multiClassification) {
      for (var entry in _projects) {
        entry.labelEntries.clear();
      }
    } else if (newMode == LabelingMode.segmentation) {
      for (var entry in _projects) {
        entry.labelEntries.clear();
      }
    }
  }
}
