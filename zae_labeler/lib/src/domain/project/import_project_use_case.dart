// lib/src/domain/project/import_project_use_case.dart

import '../../utils/storage_helper.dart';
import '../validator/project_validator.dart';
import 'save_project_use_case.dart';

/// ✅ UseCase: 프로젝트 가져오기 (Import)
/// - 외부에서 프로젝트 데이터를 가져와 저장
class ImportProjectUseCase {
  final StorageHelperInterface storageHelper;
  final SaveProjectUseCase saveProjectUseCase;

  ImportProjectUseCase({
    required this.storageHelper,
    required this.saveProjectUseCase,
  });

  /// 🔹 외부에서 프로젝트들을 가져와 저장합니다.
  Future<void> call() async {
    final imported = await storageHelper.loadProjectFromConfig('import');
    if (imported.isEmpty) {
      throw StateError('⚠️ 가져온 프로젝트가 없습니다.');
    }

    final project = imported.first; // 단일 프로젝트만 가져온다고 가정
    ProjectValidator.validate(project);
    await saveProjectUseCase.saveOne(project);
  }
}
