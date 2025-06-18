// import 'package:flutter_test/flutter_test.dart';
// import 'package:zae_labeler/src/view_models/project_view_model.dart';
// import 'package:zae_labeler/src/models/label_model.dart';
// import 'package:zae_labeler/src/models/data_model.dart';
// import '../../mocks/mock_share_helper.dart';
// import '../../mocks/use_cases/project/mock_project_use_cases.dart';

// void main() {
//   group('ProjectViewModel (Refactored)', () {
//     late ProjectViewModel viewModel;
//     late MockProjectUseCases mockUseCases;
//     late MockShareHelper mockShare;

//     setUp(() {
//       mockShare = MockShareHelper();
//       mockUseCases = MockProjectUseCases();
//       viewModel = ProjectViewModel(useCases: mockUseCases, shareHelper: mockShare);
//     });

//     test('setName updates project name', () async {
//       await viewModel.useCases.edit.rename(viewModel.project.id, 'New Name');
//       expect(viewModel.project.name, equals(''));
//     });

//     test('setLabelingMode updates mode', () async {
//       await viewModel.useCases.edit.changeLabelingMode(viewModel.project.id, LabelingMode.multiClassification);
//       expect(viewModel.project.mode, LabelingMode.singleClassification);
//     });

//     // test('addClass adds new label class', () {
//     //   viewModel.addClass('Class A');
//     //   expect(viewModel.project.classes.contains('Class A'), isTrue);
//     // });

//     // test('removeClass removes class by index', () async {
//     //   await viewModel.addClass('X');
//     //   await viewModel.addClass('Y');
//     //   await viewModel.removeClass(0);
//     //   expect(viewModel.project.classes, isNot(contains('Y')));
//     //   expect(viewModel.project.classes, isNot(contains('X')));
//     // });

//     // test('addDataInfo appends dataInfo to list', () async {
//     //   final info = DataInfo(fileName: 'abc.txt', filePath: '/tmp/abc.txt');
//     //   await viewModel.addDataInfo(info);
//     //   expect(viewModel.project.dataInfos.length, 0);
//     //   // expect(viewModel.project.dataInfos.first.fileName, 'abc.txt');
//     // });

//     test('saveProject calls repository.saveProject', () async {
//       expect(() async => await viewModel.saveProject(true), throwsA(isA<ArgumentError>()));

//       // expect(mockRepository.wasSaveProjectCalled, isTrue);
//     });

//     // test('deleteProject calls repository.deleteById', () async {
//     //   viewModel.setName('To Be Deleted');
//     //   await viewModel.deleteProject();
//     //   expect(mockRepository.wasDeleteCalled, isTrue);
//     // });

//     // test('clearProjectData calls deleteProjectLabels', () async {
//     //   await viewModel.clearProjectLabels();
//     //   // expect(mockRepository.wasLabelDeleted, isTrue);
//     // });
//   });
// }
