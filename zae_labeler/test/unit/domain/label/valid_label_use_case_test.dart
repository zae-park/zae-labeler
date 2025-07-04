import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';
import '../../../mocks/use_cases/label/mock_valid_label_use_case.dart';

void main() {
  group('MockLabelValidationUseCase', () {
    late MockLabelValidationUseCase useCase;
    late Project dummyProject;
    late LabelModel dummyLabel;

    setUp(() {
      useCase = MockLabelValidationUseCase(repository: MockLabelRepository());
      dummyProject = Project(id: 'p1', name: 'Test Project', mode: LabelingMode.singleClassification, classes: ['A', 'B'], dataInfos: []);
      dummyLabel = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'd1');
    });

    test('isValid always returns true', () {
      expect(useCase.isValid(dummyProject, dummyLabel), isTrue);
    });

    test('getStatus always returns LabelStatus.complete', () {
      final status = useCase.getStatus(dummyProject, dummyLabel);
      expect(status, LabelStatus.complete);
    });

    test('getStatus handles null label safely', () {
      final status = useCase.getStatus(dummyProject, null);
      expect(status, LabelStatus.complete);
    });
  });
}
