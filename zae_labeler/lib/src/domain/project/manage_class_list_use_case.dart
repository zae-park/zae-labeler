// 📁 Manage class list
import '../../repositories/project_repository.dart';

class AddClassUseCase {
  final ProjectRepository repository;

  AddClassUseCase({required this.repository});

  Future<void> call(String projectId, String newClass) async {
    final project = await repository.findById(projectId);
    if (project != null && !project.classes.contains(newClass)) {
      final updated = [...project.classes, newClass];
      await repository.updateProjectClasses(projectId, updated);
    }
  }
}

class RemoveClassUseCase {
  final ProjectRepository repository;

  RemoveClassUseCase({required this.repository});

  Future<void> call(String projectId, int index) async {
    final project = await repository.findById(projectId);
    if (project != null && index >= 0 && index < project.classes.length) {
      final updated = List<String>.from(project.classes)..removeAt(index);
      await repository.updateProjectClasses(projectId, updated);
    }
  }
}

class EditClassUseCase {
  final ProjectRepository repository;

  EditClassUseCase({required this.repository});

  Future<void> call(String projectId, int index, String newValue) async {
    final project = await repository.findById(projectId);
    if (project != null && index >= 0 && index < project.classes.length) {
      final updated = List<String>.from(project.classes)..[index] = newValue;
      await repository.updateProjectClasses(projectId, updated);
    }
  }
}
