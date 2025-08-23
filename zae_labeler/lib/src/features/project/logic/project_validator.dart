import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';

import '../../../core/models/project/project_model.dart';

/// 프로젝트 편집/저장 시 일관성 검증 전용 유틸
/// - validate(project): 저장 직전 '전체' 검증
/// - 부분 검증 메서드: rename/모드변경/클래스/데이터 편집 시 개별 호출
class ProjectValidator {
  // --- 정책 상수 (필요 시 조정) ---
  static const int maxProjectNameLength = 100;
  static const int maxClassCount = 256;
  static const int maxClassNameLength = 64;
  static const int maxDataInfoCount = 20000;

  // 허용 문자(프로젝트/클래스 이름) — 한글/영문/숫자/공백/일부 특수문자
  static final RegExp _allowedName = RegExp(r"^[\p{L}\p{N}\s\-\._\(\)\[\]\{\}!@#\$%&\+]+$", unicode: true);

  /// ✅ 저장 직전 전체 검증 (ID/이름/클래스/데이터)
  static void validate(Project project) {
    checkProjectId(project.id);
    checkProjectName(project.name);
    checkClasses(project.classes);
    checkDataInfos(project.dataInfos);
  }

  // ---------------------------
  // 개별(부분) 검증 메서드들
  // ---------------------------

  /// 🔹 ID: 공백 금지
  static void checkProjectId(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('❌ 프로젝트 ID가 비어 있습니다.');
    }
  }

  /// 🔹 이름: 공백 금지, 길이/문자 제한
  static void checkProjectName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('❌ 프로젝트 이름이 비어 있습니다.');
    }
    if (trimmed.length > maxProjectNameLength) {
      throw ArgumentError('❌ 프로젝트 이름이 너무 깁니다. (최대 $maxProjectNameLength자)');
    }
    if (!_allowedName.hasMatch(trimmed)) {
      throw ArgumentError('❌ 프로젝트 이름에 허용되지 않는 문자가 포함되어 있습니다.');
    }
  }

  /// 🔹 클래스 목록: 비어있지 않음, 공백/중복/길이/문자 제한
  static void checkClasses(List<String> classes) {
    if (classes.isEmpty) {
      throw ArgumentError('❌ 클래스 목록이 비어 있습니다.');
    }
    if (classes.length > maxClassCount) {
      throw ArgumentError('❌ 클래스 개수가 너무 많습니다. (최대 $maxClassCount개)');
    }

    // 트림 및 케이스/중복 검사
    final trimmed = <String>[];
    final seen = <String>{}; // 중복 판정: 대소문자/양끝 공백 무시
    for (final c in classes) {
      final t = c.trim();
      if (t.isEmpty) {
        throw ArgumentError('❌ 클래스 목록에 빈 이름이 존재합니다.');
      }
      if (t.length > maxClassNameLength) {
        throw ArgumentError('❌ 클래스 이름이 너무 깁니다. (최대 $maxClassNameLength자): $t');
      }
      if (!_allowedName.hasMatch(t)) {
        throw ArgumentError('❌ 클래스 이름에 허용되지 않는 문자가 포함되어 있습니다: $t');
      }
      final key = t.toLowerCase();
      if (seen.contains(key)) {
        throw ArgumentError('❌ 클래스 이름이 중복됩니다(대소문자/공백 무시): "$t"');
      }
      seen.add(key);
      trimmed.add(t);
    }
  }

  /// 🔹 데이터 목록: 개수/중복/필수 필드
  ///
  /// DataInfo 규칙(웹/네이티브 공통):
  /// - fileName: 필수, 공백 금지
  /// - filePath 또는 base64Content 중 하나 이상 존재
  /// - (선택) 중복 판정 키: filePath가 있으면 filePath, 없으면 fileName+base64 길이
  static void checkDataInfos(List<DataInfo> dataInfos) {
    if (dataInfos.length > maxDataInfoCount) {
      throw ArgumentError('❌ 데이터 개수가 너무 많습니다. (최대 $maxDataInfoCount개)');
    }

    final seen = <String>{};
    for (final info in dataInfos) {
      final name = info.fileName.trim();
      if (name.isEmpty) {
        throw ArgumentError('❌ 데이터 항목에 파일 이름이 없습니다.');
      }

      final hasPath = (info.filePath != null && info.filePath!.trim().isNotEmpty);
      final hasBase64 = (info.base64Content != null && info.base64Content!.trim().isNotEmpty);

      if (!hasPath && !hasBase64) {
        throw ArgumentError('❌ 데이터 "$name"에 filePath/base64Content가 모두 비어 있습니다.');
      }

      // 중복 키
      final key = hasPath ? 'path:${info.filePath!.trim()}' : 'mem:$name:${info.base64Content!.length}';
      if (!seen.add(key)) {
        throw ArgumentError('❌ 데이터가 중복됩니다: "$name"');
      }
    }
  }

  // ---------------------------
  // 모드 변경시 라벨 영향 검증 (필요시 사용)
  // ---------------------------

  /// 🔹 모드 변경 전 사전 점검 (정책에 따라 사용)
  ///  - 예: 분류→세그멘테이션 이동 시 기존 라벨 존재하면 경고/차단 등
  ///  - 여기서는 "검증만" 하고 실제 삭제/변환은 UseCase에서 수행
  static void precheckModeChange({required Project project, required LabelingMode nextMode, required bool hasAnyLabels}) {
    if (project.mode == nextMode) return;

    // 기본 정책: 라벨이 남아있다면 경고 상황으로 간주
    if (hasAnyLabels) {
      // 정책에 따라 Error를 던지거나, 경고만 로그로 남기고 진행
      // throw StateError('⚠️ 모드 변경 전 기존 라벨이 존재합니다. 삭제/마이그레이션 정책을 선택하세요.');
    }
  }
}
