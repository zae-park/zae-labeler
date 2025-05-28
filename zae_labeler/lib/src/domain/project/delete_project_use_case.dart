// lib/src/domain/project/delete_project_use_case.dart

import '../../models/project_model.dart';
import '../../utils/storage_helper.dart';

/// ✅ UseCase: 프로젝트 삭제 (단일 or 전체)
class DeleteProjectUseCase {
  final StorageHelperInterface storageHelper;

  DeleteProjectUseCase({required this.storageHelper});

  /// 🔹 단일 프로젝트 삭제 (ID 기준 → 전체 저장)
  Future<void> deleteById(String projectId, List<Project> currentList) async {
    currentList.removeWhere((p) => p.id == projectId);
    await deleteAll(currentList);
  }

  /// 🔹 전체 프로젝트 리스트 저장 (삭제 후 결과 반영)
  Future<void> deleteAll(List<Project> projects) async {
    await storageHelper.saveProjectList(projects);
  }
}
