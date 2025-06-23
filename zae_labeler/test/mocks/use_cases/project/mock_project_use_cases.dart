import 'package:zae_labeler/src/domain/project/project_use_cases.dart';
import '../../repositories/mock_project_repository.dart';
import 'mock_edit_project_use_case.dart';
import 'mock_manage_project_io_use_case.dart';
import 'mock_manage_class_list_use_case.dart';
import 'mock_manage_data_info_use_case.dart';
import 'mock_share_project_use_case.dart';

class MockProjectUseCases extends ProjectUseCases {
  MockProjectUseCases({MockProjectRepository? repository})
      : super(
          repository: repository ?? _fallbackRepo,
          edit: MockEditProjectMetaUseCase(repository: repository ?? _fallbackRepo),
          classList: MockManageClassListUseCase(repository: repository ?? _fallbackRepo),
          dataInfo: MockManageDataInfoUseCase(repository: repository ?? _fallbackRepo),
          io: MockManageProjectIOUseCase(repository: repository ?? _fallbackRepo),
          share: MockShareProjectUseCase(repository: repository ?? _fallbackRepo),
        );

  static final _fallbackRepo = MockProjectRepository();
}
