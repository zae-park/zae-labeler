import '../../repositories/project_repository.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 가져오기 (Import)
/// - 외부에서 프로젝트 데이터를 가져와 저장
class ImportProjectUseCase {
  final ProjectRepository repository;

  ImportProjectUseCase({required this.repository});

  /// 🔹 외부에서 프로젝트들을 가져와 저장합니다.
  Future<void> call() async {
    final imported = await repository.importFromExternal();

    if (imported.isEmpty) {
      throw StateError('⚠️ 가져온 프로젝트가 없습니다.');
    }

    // 🔄 다수의 프로젝트 지원
    for (final project in imported) {
      ProjectValidator.validate(project);
      await repository.saveProject(project);
    }
  }
}
