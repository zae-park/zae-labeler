import 'package:zae_labeler/src/domain/project/project_use_cases.dart';
import '../../repositories/mock_project_repository.dart';
import 'mock_edit_project_use_case.dart';
import 'mock_manage_project_io_use_case.dart';
import 'mock_manage_class_list_use_case.dart';
import 'mock_manage_data_info_use_case.dart';
import 'mock_share_project_use_case.dart';

class MockProjectUseCases extends ProjectUseCases {
  static final _repo = MockProjectRepository();
  MockProjectUseCases()
      : super(
          repository: _repo,
          edit: MockEditProjectMetaUseCase(repository: _repo),
          classList: MockManageClassListUseCase(repository: _repo),
          dataInfo: MockManageDataInfoUseCase(repository: _repo),
          io: MockManageProjectIOUseCase(repository: _repo),
          share: MockShareProjectUseCase(repository: _repo),
        );
}
