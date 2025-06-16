// test/mocks/use_cases/project/mock_project_use_cases.dart
import 'package:zae_labeler/src/domain/project/project_use_cases.dart';
import '../../mock_project_repository.dart';
import 'mock_edit_project_use_case.dart';
import 'mock_io_project_use_case.dart';
import 'mock_manage_class_list_use_case.dart';
import 'mock_manage_data_info_use_case.dart';
import 'mock_share_project_use_case.dart';

class MockProjectUseCases extends ProjectUseCases {
  MockProjectUseCases()
      : super(
          repository: MockProjectRepository(),
          edit: MockEditProjectMetaUseCase(),
          classList: MockManageClassListUseCase(),
          dataInfo: MockManageDataInfoUseCase(),
          io: MockManageProjectIOUseCase(),
          share: MockShareProjectUseCase(),
        );
}
