import 'package:zae_labeler/src/domain/label/label_use_cases.dart';
import '../../mock_storage_helper.dart';
import 'mock_single_label_use_case.dart';
import 'mock_batch_label_use_case.dart';
import 'mock_valid_label_use_case.dart';
import 'mock_io_label_use_case.dart';
import '../../mock_label_repository.dart';

class MockLabelUseCases extends LabelUseCases {
  MockLabelUseCases()
      : super(
          repository: MockLabelRepository(storageHelper: MockStorageHelper()),
          single: MockSingleLabelUseCases(),
          batch: MockBatchLabelUseCases(),
          validation: MockLabelValidationUseCases(),
          io: MockLabelIOUseCases(storageHelper: MockStorageHelper()),
        );
}
