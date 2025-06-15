import 'package:zae_labeler/src/domain/app_use_cases.dart';
import 'mock_label_use_cases.dart';
import 'mock_project_use_cases.dart';

class MockAppUseCases implements AppUseCases {
  @override
  final MockLabelUseCases label;

  @override
  final MockProjectUseCases project;

  MockAppUseCases({required this.label, required this.project});
}
