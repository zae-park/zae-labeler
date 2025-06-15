import 'package:zae_labeler/src/domain/label/label_io_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../mock_label_repository.dart';
import '../../mock_storage_helper.dart';

class MockLabelIOUseCases extends LabelIOUseCases {
  MockLabelIOUseCases({required MockStorageHelper storageHelper}) : super(MockLabelRepository(storageHelper: MockStorageHelper()));

  // @override
  Future<String> exportLabelsToJson(Project project) async {
    return '{"labels": []}'; // dummy
  }

  // @override
  Future<List<LabelModel>> importLabelsFromJson(Project project, String jsonStr) async {
    return []; // 빈 리스트 반환
  }
}
