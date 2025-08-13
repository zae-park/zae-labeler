import '../../../core/models/project/project_model.dart';

class ProjectValidator {
  /// ✅ 프로젝트 유효성 검증
  /// - ID: 공백 여부 확인
  /// - 이름: 공백 여부 확인
  /// - 클래스 목록: 비어있지 않아야 함
  /// - 클래스 이름: 빈 문자열 없어야 함
  static void validate(Project project) {
    if (project.id.trim().isEmpty) {
      throw ArgumentError('❌ 프로젝트 ID가 비어 있습니다.');
    }

    if (project.name.trim().isEmpty) {
      throw ArgumentError('❌ 프로젝트 이름이 비어 있습니다.');
    }

    if (project.classes.isEmpty) {
      throw ArgumentError('❌ 클래스 목록이 비어 있습니다.');
    }

    if (project.classes.any((c) => c.trim().isEmpty)) {
      throw ArgumentError('❌ 클래스 목록에 빈 이름이 존재합니다.');
    }
  }
}
