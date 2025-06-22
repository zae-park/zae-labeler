import 'package:zae_labeler/src/domain/label/label_use_cases.dart';
import '../../repositories/mock_label_repository.dart';
import 'mock_single_label_use_case.dart';
import 'mock_batch_label_use_case.dart';
import 'mock_valid_label_use_case.dart';
import 'mock_io_label_use_case.dart';

class MockLabelUseCases extends LabelUseCases {
  MockLabelUseCases({MockLabelRepository? repository})
      : super(
          repository: repository ?? _fallbackRepo,
          single: MockSingleLabelUseCase(repository: repository ?? _fallbackRepo),
          batch: MockBatchLabelUseCase(repository: repository ?? _fallbackRepo),
          validation: MockLabelValidationUseCase(repository: repository ?? _fallbackRepo),
          io: MockLabelIOUseCase(repository: repository ?? _fallbackRepo),
        );

  static final _fallbackRepo = MockLabelRepository();
}
