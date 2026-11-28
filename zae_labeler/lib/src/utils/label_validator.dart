// lib/src/utils/label_validator.dart
import '../core/models/project/project_model.dart';
import '../core/models/label/label_model.dart';
import '../core/models/label/classification_label_model.dart';
import '../core/models/label/segmentation_label_model.dart';

/// ✅ 라벨 유효성 검사기
class LabelValidator {
  /// ✅ 라벨이 프로젝트 설정에 맞게 유효한지 검사
  static bool isValid(LabelModel lm, Project project) {
    if (lm is SingleClassificationLabelModel) {
      return project.classes.contains(lm.label);
    } else if (lm is MultiClassificationLabelModel) {
      return lm.label!.isNotEmpty && lm.label!.every(project.classes.contains);
    } else if (lm is CrossClassificationLabelModel) {
      final relation = lm.label?.relation ?? '';
      return relation.isNotEmpty && project.classes.contains(relation);
    } else if (lm is SingleClassSegmentationLabelModel) {
      // 🔧 구현 예정 (현재는 기본값 true)
      return lm.isLabeled;
    } else if (lm is MultiClassSegmentationLabelModel) {
      // 🔧 구현 예정 (현재는 기본값 true)
      return lm.isLabeled;
    }
    return false;
  }

  /// ✅ 라벨 상태 (완료, 주의, 미완료) 반환
  static LabelStatus getStatus(Project project, LabelModel? label) {
    if (label == null || !label.isLabeled) return LabelStatus.incomplete;
    return isValid(label, project) ? LabelStatus.complete : LabelStatus.warning;
  }
}
