// 📁 Clear labels
import '../../repositories/project_repository.dart';

class ClearLabelDataUseCase {
  final ProjectRepository repository;

  ClearLabelDataUseCase({required this.repository});

  Future<void> call(String projectId) async {
    await repository.clearLabels(projectId);
  }
}
