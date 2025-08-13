import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';

void main() {
  group('Project model', () {
    test('serialization round-trip', () {
      final project = Project(
        id: 'abc-123',
        name: 'My Project',
        mode: LabelingMode.singleClassification,
        classes: ['A', 'B'],
      );

      final json = project.toJson();
      final restored = Project.fromJson(json);

      expect(restored.id, equals(project.id));
      expect(restored.name, equals(project.name));
      expect(restored.mode, equals(project.mode));
      expect(restored.classes, equals(project.classes));
    });

    // test('default values are valid', () {
    //   final project = Project.empty();
    //   expect(project.classes, isNotEmpty);
    //   expect(project.dataPaths, isEmpty);
    // });
  });
}
