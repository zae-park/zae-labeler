import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/share_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/helpers/mock_share_helper.dart';
import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('ShareProjectUseCase', () {
    late ShareProjectUseCase useCase;
    late MockProjectRepository repo;
    late MockShareHelper mockHelper;

    setUp(() {
      repo = MockProjectRepository();
      mockHelper = MockShareHelper();
      useCase = ShareProjectUseCase(repository: repo);
    });

    test('shareProject calls helper with config', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'TestProj');
      await repo.saveProject(project);

      await useCase.call(project);

      expect(mockHelper.wasCalled, true);
    });
  });
}
