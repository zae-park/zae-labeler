import '../../models/label_model.dart';
import '../../repositories/label_repository.dart';

class SingleLabelUseCases {
  final LabelRepository repository;

  SingleLabelUseCases(this.repository);

  Future<LabelModel> loadLabel(...) => repository.loadLabel(...);
  Future<void> saveLabel(...) => repository.saveLabel(...);
  Future<LabelModel> loadOrCreateLabel(...) => repository.loadOrCreateLabel(...);
  bool isLabeled(LabelModel label) => repository.isLabeled(label);
}
