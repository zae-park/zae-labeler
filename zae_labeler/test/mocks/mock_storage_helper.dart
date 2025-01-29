// test/mocks/mock_storage_helper.dart
import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_entry.dart';
import 'package:zae_labeler/src/models/data_model.dart';

class MockStorageHelper extends StorageHelperInterface {
  @override
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<DataPath> fileDataList) async {
    return 'mock_zip_path.zip'; // ✅ Mock 응답 반환
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    // ✅ 파일 저장을 수행하지 않음 (테스트용)
  }

  @override
  Future<List<Project>> loadProjects() async {
    return []; // ✅ 빈 리스트 반환
  }

  @override
  Future<List<LabelEntry>> loadLabelEntries() async {
    return []; // ✅ 빈 리스트 반환
  }

  @override
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    // ✅ 수행하지 않음
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    return 'mock_config.json';
  }

  @override
  Future<List<LabelEntry>> importLabelEntries() async {
    return [];
  }
}
