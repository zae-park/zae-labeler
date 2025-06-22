import 'package:zae_labeler/src/domain/label/label_use_cases.dart';
import '../../repositories/mock_label_repository.dart';
import 'mock_single_label_use_case.dart';
import 'mock_batch_label_use_case.dart';
import 'mock_valid_label_use_case.dart';
import 'mock_io_label_use_case.dart';

class MockLabelUseCases extends LabelUseCases {
  static final _repo = MockLabelRepository();
  MockLabelUseCases()
      : super(
          repository: _repo,
          single: MockSingleLabelUseCase(repository: _repo),
          batch: MockBatchLabelUseCase(repository: _repo),
          validation: MockLabelValidationUseCase(repository: _repo),
          io: MockLabelIOUseCase(repository: _repo),
        );
}
