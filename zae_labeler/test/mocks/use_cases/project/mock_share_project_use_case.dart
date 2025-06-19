import 'package:zae_labeler/src/domain/project/share_project_use_case.dart';
import '../../mock_project_repository.dart';

class MockShareProjectUseCase extends ShareProjectUseCase {
  MockShareProjectUseCase() : super(repository: MockProjectRepository());
}
