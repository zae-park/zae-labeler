import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';

/// ✅ UseCase: 프로젝트 설정 내보내기
/// - 프로젝트를 JSON 형태로 직렬화하고 저장/다운로드 가능한 경로를 반환합니다.
class ExportProjectUseCase {
  final ProjectRepository repository;

  ExportProjectUseCase({required this.repository});

  /// 🔹 단일 프로젝트를 외부로 내보냅니다.
  Future<String> call(Project project) async {
    return await repository.exportConfig(project);
  }
}
