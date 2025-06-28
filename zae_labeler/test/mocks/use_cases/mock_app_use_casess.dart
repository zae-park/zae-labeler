// test/mocks/use_cases/mock_app_use_cases.dart
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import '../repositories/mock_label_repository.dart';
import '../repositories/mock_project_repository.dart';
import 'label/mock_label_use_cases.dart';
import 'project/mock_project_use_cases.dart';

class MockAppUseCases extends AppUseCases {
  static final _projectRepo = MockProjectRepository();
  static final _labelRepo = MockLabelRepository();

  MockAppUseCases() : super(project: MockProjectUseCases(repository: _projectRepo), label: MockLabelUseCases(repository: _labelRepo));
}
