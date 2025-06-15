import '../../lib/src/domain/project/project_use_cases.dart';
import '../../lib/src/models/project_model.dart';

class MockProjectUseCases extends ProjectUseCases {
  @override
  final edit = MockProjectEditUseCase();

  // 필요 시 다른 서브 UseCase도 추가
}

class MockProjectEditUseCase {
  Future<void> changeLabelingMode(String projectId, LabelingMode newMode) async {}
}
