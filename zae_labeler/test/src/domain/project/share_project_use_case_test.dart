import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/domain/project/share_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../../mocks/mock_project_repository.dart';
import '../../../mocks/mock_share_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareProjectUseCase', () {
    late MockShareHelper mockHelper;
    late MockProjectRepository repository;
    late ShareProjectUseCase useCase;
    late Project testProject;

    setUp(() {
      mockHelper = MockShareHelper();
      repository = MockProjectRepository();
      useCase = ShareProjectUseCase(repository: repository);
      testProject = Project.empty().copyWith(id: 'p1', name: 'Shared Project');
    });

    testWidgets('calls shareProject and sets state', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      await useCase.call(context, testProject);

      expect(mockHelper.wasCalled, isTrue);
      expect(mockHelper.sharedName, equals('Shared Project'));
      expect(mockHelper.sharedJson, contains('"id":"p1"'));
      expect(mockHelper.resolvedFilePath, endsWith('.json'));
    });
  });
}
