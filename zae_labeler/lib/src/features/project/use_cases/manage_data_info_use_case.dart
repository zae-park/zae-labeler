// 📁 Manage data
import '../../../core/models/data/data_model.dart';
import '../models/project_model.dart';
import '../repository/project_repository.dart';

class ManageDataInfoUseCase {
  final ProjectRepository repository;

  ManageDataInfoUseCase({required this.repository});

  Future<Project?> addData({required String projectId, required DataInfo dataInfo}) async {
    await repository.addDataInfo(projectId, dataInfo);
    return await repository.findById(projectId);
  }

  Future<Project?> removeData({required String projectId, required int dataIndex}) async {
    final project = await repository.findById(projectId);
    if (project == null || dataIndex < 0 || dataIndex >= project.dataInfos.length) return project;
    final removeId = project.dataInfos[dataIndex].id;
    await repository.removeDataInfoById(projectId, removeId);
    return await repository.findById(projectId);
  }

  Future<Project?> removeAll(String projectId) async {
    await repository.updateDataInfos(projectId, []);
    return await repository.findById(projectId);
  }
}
