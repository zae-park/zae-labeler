// 📁 Manage class list
import '../models/project_model.dart';
import '../repository/project_repository.dart';

class ManageClassListUseCase {
  final ProjectRepository repository;

  ManageClassListUseCase({required this.repository});

  Future<Project?> addClass(String projectId, String newClass) async {
    final project = await repository.findById(projectId);
    if (project == null) return null;
    if (project.classes.contains(newClass)) return project;
    final updated = [...project.classes, newClass];
    await repository.updateProjectClasses(projectId, updated);
    return await repository.findById(projectId);
  }

  Future<Project?> removeClass(String projectId, int index) async {
    final project = await repository.findById(projectId);
    if (project == null || index < 0 || index >= project.classes.length) return project;
    final updated = List<String>.from(project.classes)..removeAt(index);
    await repository.updateProjectClasses(projectId, updated);
    return await repository.findById(projectId);
  }

  Future<Project?> editClass(String projectId, int index, String newName) async {
    final project = await repository.findById(projectId);
    if (project == null || index < 0 || index >= project.classes.length) return project;
    final updated = List<String>.from(project.classes)..[index] = newName;
    await repository.updateProjectClasses(projectId, updated);
    return await repository.findById(projectId);
  }
}
