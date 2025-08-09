import 'package:zae_labeler/src/features/project/use_cases/manage_data_info_use_case.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';

/// ManageDataInfoUseCase의 테스트용 모의 구현
/// 실패 상황에서는 예외를 던지는 대신 null 또는 원본 프로젝트를 반환하도록 수정했습니다.
class MockManageDataInfoUseCase extends ManageDataInfoUseCase {
  Project? mockProject;
  List<DataInfo> historyAdded = [];
  List<int> historyRemoved = [];
  bool throwOnAdd = false;
  bool throwOnRemove = false;

  MockManageDataInfoUseCase({required super.repository});

  @override
  Future<Project?> addData({required String projectId, required DataInfo dataInfo}) async {
    if (throwOnAdd) throw Exception('Add failed');
    final project = mockProject;
    if (project == null) {
      return null;
    }
    historyAdded.add(dataInfo);
    final updatedList = [...project.dataInfos, dataInfo];
    mockProject = project.copyWith(dataInfos: updatedList);
    return mockProject;
  }

  @override
  Future<Project?> removeData({required String projectId, required int dataIndex}) async {
    if (throwOnRemove) throw Exception('Remove failed');
    final project = mockProject;
    if (project == null) {
      return null;
    }
    if (dataIndex < 0 || dataIndex >= project.dataInfos.length) {
      return project; // 잘못된 인덱스는 원본 반환
    }
    historyRemoved.add(dataIndex);
    final updatedList = List<DataInfo>.from(project.dataInfos)..removeAt(dataIndex);
    mockProject = project.copyWith(dataInfos: updatedList);
    return mockProject;
  }

  @override
  Future<Project?> removeAll(String projectId) async {
    final project = mockProject;
    if (project == null) {
      return null;
    }
    mockProject = project.copyWith(dataInfos: []);
    return mockProject;
  }
}
