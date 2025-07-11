import '../repository/project_repository.dart';
import 'manage_project_io_use_case.dart';
import 'edit_project_meta_use_case.dart';
import 'manage_class_list_use_case.dart';
import 'manage_data_info_use_case.dart';
import 'share_project_use_case.dart';

/// 🧩 ViewModel에 주입하기 위한 Project 관련 UseCase 모음
class ProjectUseCases {
  final ProjectRepository repository;
  final EditProjectMetaUseCase edit;
  final ManageClassListUseCase classList;
  final ManageDataInfoUseCase dataInfo;
  final ManageProjectIOUseCase io;
  final ShareProjectUseCase share;

  ProjectUseCases({
    required this.repository,
    required this.edit,
    required this.classList,
    required this.dataInfo,
    required this.io,
    required this.share,
  });

  /// 생성자 단일화
  factory ProjectUseCases.from(ProjectRepository repository) {
    return ProjectUseCases(
      repository: repository,
      edit: EditProjectMetaUseCase(repository: repository),
      classList: ManageClassListUseCase(repository: repository),
      dataInfo: ManageDataInfoUseCase(repository: repository),
      io: ManageProjectIOUseCase(repository: repository),
      share: ShareProjectUseCase(repository: repository),
    );
  }
}
