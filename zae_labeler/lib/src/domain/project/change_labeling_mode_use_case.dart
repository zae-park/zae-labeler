// 📁 Change labeling mode
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';

class ChangeLabelingModeUseCase {
  final ProjectRepository repository;

  ChangeLabelingModeUseCase({required this.repository});

  Future<Project?> call(String projectId, LabelingMode newMode) async {
    await repository.clearLabels(projectId);
    return await repository.updateProjectMode(projectId, newMode);
  }
}
