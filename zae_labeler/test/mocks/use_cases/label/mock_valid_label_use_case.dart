import 'package:zae_labeler/src/domain/label/validate_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../mock_label_repository.dart';
import '../../mock_storage_helper.dart';

class MockLabelValidationUseCases extends LabelValidationUseCases {
  MockLabelValidationUseCases() : super(MockLabelRepository(storageHelper: MockStorageHelper()));

  // @override
  LabelStatus validate(LabelModel label) {
    return LabelStatus.complete; // 테스트용 항상 완료
  }

  // @override
  List<LabelStatus> validateAll(List<LabelModel> labels) {
    return List.filled(labels.length, LabelStatus.complete);
  }
}
