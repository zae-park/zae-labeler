import '../../models/label_model.dart';
import '../../repositories/label_repository.dart';

class BatchLabelUseCase {
  final LabelRepository repository;

  BatchLabelUseCase(this.repository);

  Future<List<LabelModel>> loadAllLabels(String projectId) => repository.loadAllLabels(projectId);
  Future<Map<String, LabelModel>> loadLabelMap(String projectId) => repository.loadLabelMap(projectId);
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) => repository.saveAllLabels(projectId, labels);
  Future<void> deleteAllLabels(String projectId) => repository.deleteAllLabels(projectId);
}
