import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/domain/project/share_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/utils/proxy_share_helper/interface_share_helper.dart';

class MockShareHelper extends Mock implements ShareHelperInterface {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareProjectUseCase', () {
    late MockShareHelper mockHelper;
    late ShareProjectUseCase useCase;
    late Project testProject;

    setUp(() {
      mockHelper = MockShareHelper();
      useCase = ShareProjectUseCase(shareHelper: mockHelper);
      testProject = Project.empty().copyWith(id: 'p1', name: 'Shared Project');
    });

    testWidgets('calls shareJson with encoded project', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox())); // mount to get context
      final realContext = tester.element(find.byType(SizedBox));

      await useCase.call(realContext, testProject);

      verify(mockHelper.shareJson(any, any)).called(1);
    });
  });
}
