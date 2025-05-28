// lib/src/domain/project/export_project_use_case.dart

import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../utils/storage_helper.dart';

/// ✅ UseCase: 프로젝트 설정 다운로드 (JSON으로 변환 후 클립보드 복사 or 임시 저장)
class ExportProjectUseCase {
  final StorageHelperInterface storageHelper;

  ExportProjectUseCase({required this.storageHelper});

  Future<String> call(BuildContext context, Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }
}
