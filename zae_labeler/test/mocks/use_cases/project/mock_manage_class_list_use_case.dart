import 'package:zae_labeler/src/domain/project/manage_class_list_use_case.dart';
import '../../mock_project_repository.dart';

class MockManageClassListUseCase extends ManageClassListUseCase {
  MockManageClassListUseCase() : super(repository: MockProjectRepository());

  // @override
  // Future<Project> addClass(String projectId, String newClass) async {}

  // @override
  // Future<Project> removeClass(String projectId, String className) async {}
}
