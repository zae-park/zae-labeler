// test/mocks/use_cases/mock_label_use_cases.dart
import 'package:zae_labeler/src/domain/label/label_use_cases.dart';
import '../../mock_label_repository.dart';
import '../../mock_storage_helper.dart';

class MockLabelUseCases {
  static LabelUseCases create() {
    final repo = MockLabelRepository(storageHelper: MockStorageHelper());
    return LabelUseCases.from(repo);
  }
}
