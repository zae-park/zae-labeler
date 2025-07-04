import '../models/label_model.dart';
import '../../project/models/project_model.dart';
import '../../../core/models/data_model.dart';
import '../repository/label_repository.dart';

/// ✅ 라벨의 외부 입출력 처리용 UseCase 모음
class LabelIOUseCase {
  final LabelRepository repository;

  LabelIOUseCase({required this.repository});

  /// 📤 라벨만 export (데이터 제외)
  Future<String> exportLabels(Project project, List<LabelModel> labels) => repository.exportLabels(project, labels);

  /// 📤 라벨 + 데이터 정보 함께 export
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) =>
      repository.exportLabelsWithData(project, labels, dataInfos);

  /// 📥 외부에서 라벨 import
  Future<List<LabelModel>> importLabels() => repository.importLabels();
}
