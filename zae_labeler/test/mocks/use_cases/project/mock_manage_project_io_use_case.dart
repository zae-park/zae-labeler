import 'package:zae_labeler/src/domain/project/manage_project_io_use_case.dart';
import '../../mock_project_repository.dart';

class MockManageProjectIOUseCase extends ManageProjectIOUseCase {
  MockManageProjectIOUseCase() : super(repository: MockProjectRepository());

  Future<void> saveProject(String projectId) async {}

  Future<void> deleteProject(String projectId) async {}
}
