import '../../repositories/label_repository.dart';
import 'single_label_use_case.dart';
import 'batch_label_use_case.dart';
import 'validate_label_use_case.dart';
import 'label_io_use_case.dart';

/// 🧩 ViewModel에 주입하기 위한 Label 관련 UseCase 모음
class LabelUseCases {
  final LabelRepository repository;
  final SingleLabelUseCases single;
  final BatchLabelUseCases batch;
  final LabelValidationUseCases validation;
  final LabelIOUseCases io;

  LabelUseCases._({required this.repository, required this.single, required this.batch, required this.validation, required this.io});

  factory LabelUseCases.from(LabelRepository repository) => LabelUseCases._(
        repository: repository,
        single: SingleLabelUseCases(repository),
        batch: BatchLabelUseCases(repository),
        validation: LabelValidationUseCases(repository),
        io: LabelIOUseCases(repository),
      );
}
