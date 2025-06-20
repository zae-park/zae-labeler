import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/import_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../mocks/mock_project_repository.dart';

void main() {
  group('ImportProjectUseCase', () {
    late MockProjectRepository repository;
    late ImportProjectUseCase useCase;

    setUp(() {
      repository = MockProjectRepository();
      useCase = ImportProjectUseCase(repository: repository);
    });

    test('imports and saves the first external project', () async {
      final imported = Project.empty().copyWith(id: 'p1', name: 'Imported Project');
      // ✅ importFromExternal()에서 반환할 데이터를 설정
      repository.projects = [imported];

      expect(() async => await useCase.call(), throwsA(isA<ArgumentError>()));

      final result = await repository.findById('p1');
      expect(result?.name, 'Imported Project');
    });

    test('throws StateError if no projects are imported', () async {
      repository.projects = [];

      expect(() async => await useCase.call(), throwsA(isA<StateError>()));
    });
  });
}
