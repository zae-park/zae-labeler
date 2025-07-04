import '../../../core/models/label_model.dart';
import '../../../core/models/project_model.dart';
import '../repository/label_repository.dart';

/// ✅ 라벨 유효성 검사 및 상태 판단용 UseCase 모음
class LabelValidationUseCase {
  final LabelRepository repository;

  LabelValidationUseCase({required this.repository});

  /// 📌 주어진 프로젝트 기준으로 라벨이 유효한지 판단
  bool isValid(Project project, LabelModel label) => repository.isValid(project, label);

  /// 📌 라벨 상태를 반환 (완료/주의/미완료)
  LabelStatus getStatus(Project project, LabelModel? label) => repository.getStatus(project, label);
}
