import '../../models/label_model.dart';
import '../../repositories/label_repository.dart';

class LabelValidationUseCases {
  final LabelRepository repository;

  LabelValidationUseCases(this.repository);

  bool isValid(Project project, LabelModel label) => repository.isValid(project, label);
  LabelStatus getStatus(Project project, LabelModel? label) => repository.getStatus(project, label);
}
