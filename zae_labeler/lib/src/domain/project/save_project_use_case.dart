// lib/src/domain/project/save_project_use_case.dart

import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 저장 (단일 or 전체)
class SaveProjectUseCase {
  final ProjectRepository repository;

  SaveProjectUseCase({required this.repository});

  /// 🔹 단일 프로젝트 저장
  /// - 유효성 검사 후 repository를 통해 저장
  Future<void> saveOne(Project project) async {
    ProjectValidator.validate(project);
    await repository.saveProject(project);
  }

  /// 🔹 전체 프로젝트 리스트 저장
  Future<void> saveAll(List<Project> projects) async {
    await repository.saveAll(projects);
  }
}
