import 'package:zae_labeler/src/domain/label/validate_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

class MockLabelValidationUseCase extends LabelValidationUseCase {
  MockLabelValidationUseCase({required super.repository});

  @override
  bool isValid(Project project, LabelModel label) => true;

  @override
  LabelStatus getStatus(Project project, LabelModel? label) => LabelStatus.complete;
}
