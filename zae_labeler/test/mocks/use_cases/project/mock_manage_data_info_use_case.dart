import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/project/use_cases/manage_data_info_use_case.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';

class MockManageDataInfoUseCase extends ManageDataInfoUseCase {
  Project? mockProject;
  List<DataInfo> historyAdded = [];
  List<int> historyRemoved = [];
  bool throwOnAdd = false;
  bool throwOnRemove = false;

  MockManageDataInfoUseCase({required super.repository});

  @override
  Future<Project> addData({required String projectId, required DataInfo dataInfo}) async {
    if (throwOnAdd) throw Exception('Add failed');
    if (mockProject == null) throw Exception('Project not found');

    historyAdded.add(dataInfo);
    final updatedList = [...mockProject!.dataInfos, dataInfo];
    mockProject = mockProject!.copyWith(dataInfos: updatedList);
    return mockProject!;
  }

  @override
  Future<Project> removeData({required String projectId, required int dataIndex}) async {
    if (throwOnRemove) throw Exception('Remove failed');
    if (mockProject == null) throw Exception('Project not found');
    if (dataIndex < 0 || dataIndex >= mockProject!.dataInfos.length) throw Exception('Invalid index');

    historyRemoved.add(dataIndex);
    final updatedList = List<DataInfo>.from(mockProject!.dataInfos)..removeAt(dataIndex);
    mockProject = mockProject!.copyWith(dataInfos: updatedList);
    return mockProject!;
  }

  @override
  Future<Project> removeAll(String projectId) async {
    if (mockProject == null) throw Exception('Project not found');
    mockProject = mockProject!.copyWith(dataInfos: []);
    return mockProject!;
  }
}
