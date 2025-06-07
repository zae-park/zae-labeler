// 📁 Manage data
import '../../models/data_model.dart';
import '../../repositories/project_repository.dart';

class AddDataInfoUseCase {
  final ProjectRepository repository;

  AddDataInfoUseCase({required this.repository});

  Future<void> call(String projectId, DataInfo newDataInfo) async {
    await repository.addDataInfo(projectId, newDataInfo);
  }
}

class RemoveDataInfoUseCase {
  final ProjectRepository repository;

  RemoveDataInfoUseCase({required this.repository});

  Future<void> call(String projectId, String dataId) async {
    await repository.removeDataInfoById(projectId, dataId);
  }
}
