import '../models/label_model.dart';
import '../repository/label_repository.dart';

/// ✅ 단일 데이터 항목에 대한 라벨 처리용 UseCase 모음
class SingleLabelUseCase {
  final LabelRepository repository;

  SingleLabelUseCase({required this.repository});

  /// 📌 단일 라벨 로드
  Future<LabelModel> loadLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) =>
      repository.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);

  /// 📌 단일 라벨 저장
  Future<void> saveLabel({required String projectId, required String dataId, required String dataPath, required LabelModel labelModel}) =>
      repository.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);

  /// 📌 라벨 로드 or 새로 생성
  Future<LabelModel> loadOrCreateLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) =>
      repository.loadOrCreateLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);

  /// 📌 라벨이 완전히 작성되었는지 여부
  bool isLabeled(LabelModel labelModel) => repository.isLabeled(labelModel);
}
