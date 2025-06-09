import '../../models/label_model.dart';
import '../../repositories/label_repository.dart';

class LabelIOUseCases {
  final LabelRepository repository;

  LabelIOUseCases(this.repository);

  Future<String> exportLabels(...) => repository.exportLabels(...);
  Future<String> exportLabelsWithData(...) => repository.exportLabelsWithData(...);
  Future<List<LabelModel>> importLabels() => repository.importLabels();
}

