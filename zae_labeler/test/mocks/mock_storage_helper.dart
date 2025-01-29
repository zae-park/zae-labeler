import 'package:zae_labeler/src/utils/storage_helper.dart';

class MockStorageHelper extends StorageHelper {
  @override
  Future<String> downloadLabelsAsZip(project, labelEntries, dataPaths) async {
    return 'mock_zip_path.zip'; // 실제 파일 대신 Mock 데이터 반환
  }

  @override
  Future<void> saveProjects(List projects) async {
    // 파일 저장을 수행하지 않음 (테스트에서는 필요 없음)
  }
}
