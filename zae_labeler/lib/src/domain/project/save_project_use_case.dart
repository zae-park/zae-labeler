// lib/src/domain/project/save_project_use_case.dart

import '../../models/project_model.dart';
import '../../utils/storage_helper.dart';

/// ✅ UseCase: 프로젝트 저장 (단일 or 전체)
/// - `saveOne`: 리스트 내 추가 또는 수정 후 전체 저장
/// - `saveAll`: 외부에서 준비된 전체 리스트 저장
class SaveProjectUseCase {
  final StorageHelperInterface storageHelper;

  SaveProjectUseCase({required this.storageHelper});

  /// 🔹 단일 프로젝트 저장 (리스트 수정 후 전체 저장)
  Future<void> saveOne(Project project, List<Project> currentList) async {
    final index = currentList.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      currentList[index] = project;
    } else {
      currentList.add(project);
    }

    await saveAll(currentList);
  }

  /// 🔹 전체 프로젝트 리스트 저장
  Future<void> saveAll(List<Project> projects) async {
    await storageHelper.saveProjectList(projects);
  }
}
