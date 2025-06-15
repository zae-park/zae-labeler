// test/mocks/use_cases/mock_label_use_cases.dart
import 'package:zae_labeler/src/domain/project/project_use_cases.dart';
import '../../mock_project_repository.dart';

class MockProjectUseCases {
  static ProjectUseCases create() {
    final repo = MockProjectRepository();
    return ProjectUseCases.from(repo);
  }
}
