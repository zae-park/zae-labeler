// 📁 Manage data
import '../../../core/models/data_model.dart';
import '../../../core/models/project_model.dart';
import '../../../core/repositories/project_repository.dart';

class ManageDataInfoUseCase {
  final ProjectRepository repository;

  ManageDataInfoUseCase({required this.repository});

  Future<Project> addData({required String projectId, required DataInfo dataInfo}) async {
    final project = await repository.findById(projectId);
    if (project != null) {
      final updatedList = [...project.dataInfos, dataInfo];
      final updatedProject = project.copyWith(dataInfos: updatedList);
      await repository.saveProject(updatedProject);
      return updatedProject;
    }
    throw Exception('Project not found');
  }

  Future<Project> removeData({required String projectId, required int dataIndex}) async {
    final project = await repository.findById(projectId);
    if (project != null && dataIndex >= 0 && dataIndex < project.dataInfos.length) {
      final updatedList = List<DataInfo>.from(project.dataInfos)..removeAt(dataIndex);
      final updatedProject = project.copyWith(dataInfos: updatedList);
      await repository.saveProject(updatedProject);
      return updatedProject;
    }
    throw Exception('Invalid project or data index');
  }

  Future<Project> removeAll(String projectId) async {
    final project = await repository.findById(projectId);
    if (project != null) {
      final updatedProject = project.copyWith(dataInfos: []);
      await repository.saveProject(updatedProject);
      return updatedProject;
    }
    throw Exception('Project not found');
  }
}
