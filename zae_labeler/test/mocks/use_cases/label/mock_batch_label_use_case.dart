import 'package:zae_labeler/src/domain/label/batch_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../mock_label_repository.dart';
import '../../mock_storage_helper.dart';

class MockBatchLabelUseCases extends BatchLabelUseCases {
  MockBatchLabelUseCases() : super(MockLabelRepository(storageHelper: MockStorageHelper()));

  // @override
  // Future<List<LabelModel>> loadAllLabels(String projectId) async {
  //   return dataPaths.map((e) => LabelModelFactory.createNew(mode, dataId: 'mock')).toList();
  // }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {}
}
