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
    // 외부에서 가져오기 (예: JSON import dialog → 파일 선택)
    final imported = await storageHelper.loadProjectFromConfig('import');
    ProjectValidator.validate(imported);
    // 불러온 프로젝트를 저장
    await saveProjectUseCase.saveAll(imported);
  }
}
