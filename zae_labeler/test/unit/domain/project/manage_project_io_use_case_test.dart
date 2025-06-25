import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/manage_project_io_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/helpers/mock_storage_helper.dart';
import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('ManageProjectIOUseCase', () {
    late MockProjectRepository repo;
    late ManageProjectIOUseCase useCase;

    setUp(() {
      repo = MockProjectRepository();
      useCase = ManageProjectIOUseCase(repository: repo);
    });

    test('saveOne stores a valid project', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'Project A', classes: ['A']);
      await useCase.saveOne(project);

      final result = await repo.findById('p1');
      expect(result?.name, 'Project A');
      expect(result?.classes, contains('A'));
    });

    test('saveAll stores multiple projects', () async {
      final projects = [
        Project.empty().copyWith(id: 'p1', name: 'P1'),
        Project.empty().copyWith(id: 'p2', name: 'P2'),
      ];

      await useCase.saveAll(projects);
      final all = await repo.fetchAllProjects();
      expect(all.length, 2);
      expect(all.any((p) => p.name == 'P1'), isTrue);
      expect(all.any((p) => p.name == 'P2'), isTrue);
    });

    test('deleteById removes specific project', () async {
      final project = Project.empty().copyWith(id: 'p1');
      await repo.saveProject(project);

      await useCase.deleteById('p1');
      final result = await repo.findById('p1');
      expect(result, isNull);
    });

    test('deleteAll removes multiple projects', () async {
      final p1 = Project.empty().copyWith(id: 'p1');
      final p2 = Project.empty().copyWith(id: 'p2');
      await repo.saveProject(p1);
      await repo.saveProject(p2);

      await useCase.deleteAll(['p1', 'p2']);
      final result = await repo.fetchAllProjects();
      expect(result, isEmpty);
    });

    test('fetchAll returns all saved projects', () async {
      final p1 = Project.empty().copyWith(id: 'p1');
      final p2 = Project.empty().copyWith(id: 'p2');
      await repo.saveAll([p1, p2]);

      final result = await useCase.fetchAll();
      expect(result.length, 2);
      expect(result.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('clearCache calls storageHelper.clearAllCache', () async {
      final customStorageHelper = MockStorageHelper();
      final localRepo = MockProjectRepository(storageHelper: customStorageHelper);
      final localUseCase = ManageProjectIOUseCase(repository: localRepo);

      await localUseCase.clearCache();
      expect(customStorageHelper.wasClearCacheCalled, isTrue);
    });

    // ─────────────────────────────────────
    // 📂 Import/Export 테스트 추가
    // ─────────────────────────────────────
    test('importProjects loads from repository', () async {
      final p1 = Project.empty().copyWith(id: 'p1');
      final p2 = Project.empty().copyWith(id: 'p2');
      await repo.saveAll([p1, p2]);

      final imported = await useCase.importProjects();
      expect(imported.length, 2);
      expect(imported.map((e) => e.id), containsAll(['p1', 'p2']));
    });

    test('exportProject returns mock config path', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'ExportTest');
      final path = await useCase.exportProject(project);
      expect(path, contains('mock_config_path'));
      expect(path, contains('.json'));
    });
  });
}
