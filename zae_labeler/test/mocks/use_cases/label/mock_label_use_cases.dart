import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart';
import '../../repositories/mock_label_repository.dart';
import 'mock_single_label_use_case.dart';
import 'mock_batch_label_use_case.dart';
import 'mock_label_summary_use_case.dart';
import 'mock_valid_label_use_case.dart';
import 'mock_io_label_use_case.dart';

class MockLabelUseCases extends LabelUseCases {
  MockLabelUseCases({MockLabelRepository? repository}) : this._with(repository ?? _fallbackRepo);

  MockLabelUseCases._with(MockLabelRepository repo)
      : super(
          repository: repo,
          single: MockSingleLabelUseCase(repository: repo),
          batch: MockBatchLabelUseCase(repository: repo),
          validation: _validation,
          io: MockLabelIOUseCase(repository: repo),
          summary: MockLabelSummaryUseCase(repository: repo, validUseCase: _validation),
        );

  static final _fallbackRepo = MockLabelRepository();
  static final _validation = MockLabelValidationUseCase(repository: _fallbackRepo);
}
