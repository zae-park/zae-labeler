// 📁 Manage class list
import '../../../core/models/project_model.dart';
import '../repository/project_repository.dart';

class ManageClassListUseCase {
  final ProjectRepository repository;

  ManageClassListUseCase({required this.repository});

  Future<Project> addClass(String projectId, String newClass) async {
    final project = await repository.findById(projectId);
    if (project != null && !project.classes.contains(newClass)) {
      final updated = [...project.classes, newClass];
      final updatedProject = project.copyWith(classes: updated);
      await repository.saveProject(updatedProject);
      return updatedProject;
    }
    return project!;
  }

  Future<Project> removeClass(String projectId, int index) async {
    final project = await repository.findById(projectId);
    if (project != null && index >= 0 && index < project.classes.length) {
      final updated = List<String>.from(project.classes)..removeAt(index);
      final updatedProject = project.copyWith(classes: updated);
      await repository.saveProject(updatedProject);
      return updatedProject;
    }
    return project!;
  }

  Future<Project> editClass(String projectId, int index, String newName) async {
    final project = await repository.findById(projectId);
    if (project != null && index >= 0 && index < project.classes.length) {
      final updated = List<String>.from(project.classes)..[index] = newName;
      final updatedProject = project.copyWith(classes: updated);
      await repository.saveProject(updatedProject);
      return updatedProject;
    }
    return project!;
  }
}
