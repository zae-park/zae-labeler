// lib/src/utils/label_validator.dart
import '../models/project_model.dart';
import '../models/label_model.dart';
import '../models/sub_models/classification_label_model.dart';
import '../models/sub_models/segmentation_label_model.dart';

/// ✅ 라벨 유효성 검사기
class LabelValidator {
  /// ✅ 라벨이 프로젝트 설정에 맞게 유효한지 검사
  static bool isValid(LabelModel label, Project project) {
    if (label is SingleClassificationLabelModel) {
      return project.classes.contains(label.label);
    } else if (label is MultiClassificationLabelModel) {
      return label.label.isNotEmpty && label.label.every(project.classes.contains);
    } else if (label is SingleClassSegmentationLabelModel) {
      // 🔧 구현 예정 (현재는 기본값 true)
      return true;
    } else if (label is MultiClassSegmentationLabelModel) {
      // 🔧 구현 예정 (현재는 기본값 true)
      return true;
    }
    return false;
  }

  /// ✅ 라벨 상태 (완료, 주의, 미완료) 반환
  static LabelStatus getStatus(LabelModel? label, Project project) {
    if (label == null) return LabelStatus.incomplete;
    return isValid(label, project) ? LabelStatus.complete : LabelStatus.warning;
  }
}
