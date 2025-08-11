// lib/src/domain/project/share_project_use_case.dart

import 'dart:convert';
import '../models/project_model.dart';
import '../repository/project_repository.dart';
import '../../../platform_helpers/share/interface_share_helper.dart';
import '../../../platform_helpers/share/get_helper.dart';
import '../logic/project_validator.dart';

class ShareProjectResult {
  final bool success;
  final String? message;
  ShareProjectResult._(this.success, this.message);
  factory ShareProjectResult.success() => ShareProjectResult._(true, null);
  factory ShareProjectResult.failure(String message) => ShareProjectResult._(false, message);
}

/// ✅ UseCase: 프로젝트 공유
/// - JSON으로 직렬화한 프로젝트를 플랫폼별 공유 방식으로 전달
class ShareProjectUseCase {
  ShareHelperInterface _shareHelper;
  final ProjectRepository repository;

  set shareHelper(ShareHelperInterface helper) {
    _shareHelper = helper;
  }

  ShareProjectUseCase({required this.repository, ShareHelperInterface? shareHelper}) : _shareHelper = shareHelper ?? getShareHelper();

  // Future<void> call(BuildContext context, Project project) async {
  //   ProjectValidator.validate(project);
  //   final jsonString = jsonEncode(project.toJson());

  //   final filePath = await repository.exportConfig(project);
  //   await _shareHelper.shareProject(name: project.name, jsonString: jsonString, getFilePath: () async => filePath);
  // }
  Future<ShareProjectResult> call(Project project) async {
    try {
      ProjectValidator.validate(project);
      final jsonString = jsonEncode(project.toJson());
      final filePath = await repository.exportConfig(project);
      await _shareHelper.shareProject(name: project.name, jsonString: jsonString, getFilePath: () async => filePath);
      return ShareProjectResult.success();
    } catch (e) {
      return ShareProjectResult.failure(e.toString());
    }
  }
}
