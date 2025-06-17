import 'package:zae_labeler/src/domain/label/single_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../mock_label_repository.dart';
import '../../mock_storage_helper.dart';

class MockSingleLabelUseCases extends SingleLabelUseCases {
  MockSingleLabelUseCases() : super(MockLabelRepository(storageHelper: MockStorageHelper()));

  // @override
  Future<void> saveLabelById(String projectId, String dataId, LabelModel label) async {
    // 테스트용 no-op
  }

  // @override
  Future<LabelModel?> loadLabelById(String projectId, String dataId, LabelingMode mode) async {
    return LabelModelFactory.createNew(mode, dataId: "mock"); // dummy
  }
}
