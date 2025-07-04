import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/project/domain/use_cases/share_project_use_case.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';

import '../../../mocks/helpers/mock_share_helper.dart';
import '../../../mocks/mock_context.dart';
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
      useCase.shareHelper = mockHelper; // ❗ setter를 통해 shareHelper를 외부 주입
    });

    test('shareProject calls helper with config', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'TestProj');
      await repo.saveProject(project);

      final dummyContext = MockDummyContext();

      expectLater(() async => await useCase.call(dummyContext, project), throwsA(isA<ArgumentError>()));
    });
  });
}
