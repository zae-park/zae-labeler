import 'package:zae_labeler/src/features/label/use_cases/labeling_summary_use_case.dart';

import '../repository/label_repository.dart';
import 'single_label_use_case.dart';
import 'batch_label_use_case.dart';
import 'validate_label_use_case.dart';
import 'label_io_use_case.dart';

/// 🧩 ViewModel에 주입하기 위한 Label 관련 UseCase 모음
class LabelUseCases {
  final LabelRepository repository;
  final SingleLabelUseCase single;
  final BatchLabelUseCase batch;
  final LabelValidationUseCase validation;
  final LabelIOUseCase io;
  final LabelingSummaryUseCase summary;

  LabelUseCases({required this.repository, required this.single, required this.batch, required this.validation, required this.io, required this.summary});

  factory LabelUseCases.from(LabelRepository repository) {
    final validation = LabelValidationUseCase(repository: repository);
    return LabelUseCases(
      repository: repository,
      single: SingleLabelUseCase(repository: repository),
      batch: BatchLabelUseCase(repository: repository),
      validation: validation,
      io: LabelIOUseCase(repository: repository),
      summary: LabelingSummaryUseCase(repository: repository, validUseCase: validation),
    );
  }
}
