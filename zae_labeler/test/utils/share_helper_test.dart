import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/view_models/project_view_model.dart';
import '../mocks/mock_storage_helper.dart';

void main() {
  group('ProjectViewModel', () {
    late ProjectViewModel viewModel;
    late MockStorageHelper mockHelper;

    setUp(() {
      mockHelper = MockStorageHelper();
      viewModel = ProjectViewModel(storageHelper: mockHelper);
    });

    test('setName updates project name', () {
      viewModel.setName('New Name');
      expect(viewModel.project.name, 'New Name');
    });

    test('saveProject triggers storage saveProjectConfig', () async {
      await viewModel.saveProject(true);
      expect(mockHelper.wasSaveProjectCalled, isTrue);
    });

    // ✅ 웹 전용으로 테스트가 필요한 경우만 아래처럼 태깅!
    test('shareProject on Web uses shareTextOnWeb', () async {
      // 테스트 조건부로 분리하거나 mock 처리를 해야 함
    }, tags: ['web-only']);
  });
}
