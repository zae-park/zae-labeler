// lib/src/domain/project/save_project_use_case.dart

import '../../models/project_model.dart';
import '../../utils/storage_helper.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 저장 (단일 or 전체)
class SaveProjectUseCase {
  final StorageHelperInterface storageHelper;

  SaveProjectUseCase({required this.storageHelper});

  /// 🔹 단일 프로젝트 저장 (내부적으로 전체 리스트 불러오기)
  Future<void> saveOne(Project project) async {
    ProjectValidator.validate(project);
    final currentList = await storageHelper.loadProjectList();
    final index = currentList.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      currentList[index] = project;
    } else {
      currentList.add(project);
    }

    await saveAll(currentList);
  }

  Future<void> saveAll(List<Project> projects) async {
    await storageHelper.saveProjectList(projects);
  }
}
