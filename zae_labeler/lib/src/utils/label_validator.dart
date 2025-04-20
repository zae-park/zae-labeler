// 📁 lib/src/utils/label_validator.dart
import '../models/project_model.dart';
import '../models/label_model.dart';
import '../models/sub_models/classification_label_model.dart';
import '../models/sub_models/segmentation_label_model.dart';

/// ✅ 라벨 상태 구분
enum LabelStatus {
  complete, // ✅ 정상 라벨
  warning, // ⚠️ 존재하지만 불완전/오류
  incomplete, // ❌ 라벨 없음
}

/// ✅ 라벨 유효성 검사
bool isLabelValid(LabelModel label, Project project) {
  if (label is SingleClassificationLabelModel) {
    return project.classes.contains(label.label);
  } else if (label is MultiClassificationLabelModel) {
    return label.label.isNotEmpty && label.label.every(project.classes.contains);
  } else if (label is SingleClassSegmentationLabelModel) {
    return true;
    // return label.label.grid.isNotEmpty; // not implemented yet
  } else if (label is MultiClassSegmentationLabelModel) {
    return true;
    // return label.label.classMap.isNotEmpty; // not implemented yet
  }
  return false;
}

/// ✅ 라벨 상태 판별기
LabelStatus getLabelStatus(LabelModel? label, Project project) {
  if (label == null) return LabelStatus.incomplete;
  return isLabelValid(label, project) ? LabelStatus.complete : LabelStatus.warning;
}
