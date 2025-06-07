import 'edit_project_meta_use_case.dart';
import 'manage_class_list_use_case.dart';
import 'manage_data_info_use_case.dart';
import 'save_project_use_case.dart';
import 'share_project_use_case.dart';

/// 🧩 ViewModel에 주입하기 위한 Project 관련 UseCase 모음
class ProjectUseCases {
  final EditProjectMetaUseCase edit;
  final ManageClassListUseCase classList;
  final ManageDataInfoUseCase dataInfo;
  final SaveProjectUseCase save;
  final ShareProjectUseCase share;

  const ProjectUseCases({
    required this.edit,
    required this.classList,
    required this.dataInfo,
    required this.save,
    required this.share,
  });
}
