import 'package:zae_labeler/src/domain/project/edit_project_meta_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../mock_project_repository.dart';

class MockEditProjectMetaUseCase extends EditProjectMetaUseCase {
  MockEditProjectMetaUseCase() : super(repository: MockProjectRepository());

  @override
  Future<Project?> rename(String projectId, String newName) async =>
      Project(id: projectId, name: newName, mode: LabelingMode.singleClassification, classes: []);
}
