import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/label/validate_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';

void main() {
  group('LabelValidationUseCase', () {
    late LabelValidationUseCase useCase;
    late MockLabelRepository repo;

    setUp(() {
      repo = MockLabelRepository();
      useCase = LabelValidationUseCase(repo);
    });

    test('isValid returns true from repo', () {
      final project = Project.empty();
      final label = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'x');

      final result = useCase.isValid(project, label);
      expect(result, isTrue);
    });

    test('getStatus returns label status from repo', () {
      final project = Project.empty();
      final label = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'y');

      final result = useCase.getStatus(project, label);
      expect(result, LabelStatus.complete);

      final nullResult = useCase.getStatus(project, null);
      expect(nullResult, LabelStatus.incomplete);
    });
  });
}
