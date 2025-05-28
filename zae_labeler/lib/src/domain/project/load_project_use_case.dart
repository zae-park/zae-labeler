// lib/src/domain/project/load_projects_use_case.dart

import '../../models/project_model.dart';
import '../../utils/storage_helper.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 불러오기
/// - 전체 목록 불러오기
/// - 특정 ID의 단일 프로젝트 조회
class LoadProjectsUseCase {
  final StorageHelperInterface storageHelper;

  LoadProjectsUseCase({required this.storageHelper});

  /// 🔹 전체 프로젝트 목록 불러오기
  Future<List<Project>> loadAll() async {
    return await storageHelper.loadProjectList();
  }

  /// 🔹 특정 ID의 단일 프로젝트 불러오기
  Future<Project?> loadById(String projectId) async {
    final all = await loadAll();
    try {
      final findProject = all.firstWhere((p) => p.id == projectId);
      ProjectValidator.validate(findProject);
      return findProject;
    } catch (_) {
      return null;
    }
  }
}
