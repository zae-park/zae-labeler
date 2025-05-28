// lib/src/domain/project/share_project_use_case.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_share_helper/interface_share_helper.dart';

/// ✅ UseCase: 프로젝트 공유
/// - JSON으로 직렬화한 프로젝트를 플랫폼별 공유 방식으로 전달
class ShareProjectUseCase {
  final ShareHelperInterface shareHelper;

  ShareProjectUseCase({required this.shareHelper});

  Future<void> call(BuildContext context, Project project) async {
    try {
      final jsonString = jsonEncode(project.toJson());

      await shareHelper.shareProject(name: project.name, jsonString: jsonString, getFilePath: () async => '${project.name}.json');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 공유 실패: $e')),
      );
    }
  }
}
