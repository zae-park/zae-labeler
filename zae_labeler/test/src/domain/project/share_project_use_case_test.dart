// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter/material.dart';
// import 'package:zae_labeler/src/domain/project/share_project_use_case.dart';
// import 'package:zae_labeler/src/models/project_model.dart';
// import '../../../mocks/mock_project_repository.dart';

// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();

//   group('ShareProjectUseCase', () {
//     late MockProjectRepository repository;
//     late ShareProjectUseCase useCase;
//     late Project testProject;

//     setUp(() {
//       repository = MockProjectRepository();
//       useCase = ShareProjectUseCase(repository: repository);
//       testProject = Project.empty().copyWith(id: 'p1', name: 'Shared Project');
//     });

//     testWidgets('calls shareProject and sets state', (tester) async {
//       await tester.pumpWidget(const MaterialApp(home: SizedBox()));
//       final filePath = await repository.exportConfig(testProject);
//       useCase.shareHelper.shareProject(name: testProject.name, jsonString: testProject.toJsonString(), getFilePath: () async => filePath);
//     });
//   });
// }
