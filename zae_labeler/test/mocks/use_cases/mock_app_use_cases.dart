// test/mocks/use_cases/mock_app_use_cases.dart
import 'package:zae_labeler/src/domain/app_use_cases.dart';
import 'package:zae_labeler/src/domain/label/label_use_cases.dart';
import 'package:zae_labeler/src/domain/project/project_use_cases.dart';
import './label/mock_label_use_cases.dart' as labelMocks;
import './project/mock_project_use_cases.dart' as projectMocks;

class MockAppUseCases extends AppUseCases {
  MockAppUseCases({ProjectUseCases? project, LabelUseCases? label})
      : super(
          project: project ?? projectMocks.MockProjectUseCases.create(),
          label: label ?? labelMocks.MockLabelUseCases.create(), // factory라면 .create()
        );
}
