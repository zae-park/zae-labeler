// lib/src/domain/project/download_project_use_case.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/project_model.dart';

/// ✅ UseCase: 프로젝트 설정 다운로드 (JSON으로 변환 후 클립보드 복사 or 임시 저장)
class DownloadProjectUseCase {
  DownloadProjectUseCase();

  Future<void> call(BuildContext context, Project project) async {
    try {
      final jsonString = jsonEncode(project.toJson());

      // 현재 구조에선 클립보드 복사로 대체
      await Clipboard.setData(ClipboardData(text: jsonString));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로젝트 설정이 복사되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 다운로드 실패: $e')),
      );
    }
  }
}
