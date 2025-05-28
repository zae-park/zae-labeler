// lib/src/domain/project/save_project_use_case.dart

import '../../models/project_model.dart';
import '../../utils/storage_helper.dart';

/// ✅ UseCase: 프로젝트 저장 (신규 또는 업데이트)
class SaveProjectUseCase {
  final StorageHelperInterface storageHelper;

  SaveProjectUseCase({required this.storageHelper});

  Future<void> call(Project project, List<Project> currentList) async {
    final index = currentList.indexWhere((p) => p.id == project.id);

    if (index != -1) {
      currentList[index] = project;
    } else {
      currentList.add(project);
    }

    await storageHelper.saveProjectList(currentList);
  }
}
