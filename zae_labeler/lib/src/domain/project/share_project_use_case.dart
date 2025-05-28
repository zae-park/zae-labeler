// lib/src/domain/project/share_project_use_case.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_share_helper/interface_share_helper.dart';

/// ✅ UseCase: 프로젝트 공유
/// - 프로젝트를 JSON으로 직렬화 후, 외부 공유 호출
class ShareProjectUseCase {
  final ShareHelperInterface shareHelper;

  ShareProjectUseCase({required this.shareHelper});

  Future<void> call(BuildContext context, Project project) async {
    try {
      final json = jsonEncode(project.toJson());

      await shareHelper.shareJson(context, json);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 공유 실패: $e')),
      );
    }
  }
}
