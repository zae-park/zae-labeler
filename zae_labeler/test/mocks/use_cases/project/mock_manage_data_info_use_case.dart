import 'package:zae_labeler/src/domain/project/manage_data_info_use_case.dart';
import '../../mock_project_repository.dart';

class MockManageDataInfoUseCase extends ManageDataInfoUseCase {
  MockManageDataInfoUseCase() : super(repository: MockProjectRepository());
}
