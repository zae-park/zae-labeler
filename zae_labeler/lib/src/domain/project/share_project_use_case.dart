// lib/src/domain/project/share_project_use_case.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';
import '../../utils/proxy_share_helper/interface_share_helper.dart';
import '../../utils/share_helper.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 공유
/// - JSON으로 직렬화한 프로젝트를 플랫폼별 공유 방식으로 전달
class ShareProjectUseCase {
  ShareHelperInterface _shareHelper;
  final ProjectRepository repository;

  set shareHelper(ShareHelperInterface helper) {
    _shareHelper = helper;
  }

  ShareProjectUseCase({required this.repository, ShareHelperInterface? shareHelper}) : _shareHelper = shareHelper ?? getShareHelper();

  Future<void> call(BuildContext context, Project project) async {
    ProjectValidator.validate(project);
    final jsonString = jsonEncode(project.toJson());

    final filePath = await repository.exportConfig(project);
    await _shareHelper.shareProject(name: project.name, jsonString: jsonString, getFilePath: () async => filePath);
  }
}
