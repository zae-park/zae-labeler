// test/mocks/use_cases/mock_app_use_cases.dart
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/core/use_cases/label/label_use_cases.dart';
import 'package:zae_labeler/src/features/project/domain/use_cases/project_use_cases.dart';
import './label/mock_label_use_cases.dart' as labelMocks;
import './project/mock_project_use_cases.dart' as projectMocks;

class MockAppUseCases extends AppUseCases {
  MockAppUseCases({ProjectUseCases? project, LabelUseCases? label})
      : super(
          project: project ?? projectMocks.MockProjectUseCases(),
          label: label ?? labelMocks.MockLabelUseCases(),
        );
}
