import 'package:zae_labeler/src/utils/proxy_share_helper/interface_share_helper.dart';

class MockShareHelper implements ShareHelperInterface {
  bool wasCalled = false;
  String? sharedName;
  String? sharedJson;
  String? resolvedFilePath;

  @override
  Future<void> shareProject({
    required String name,
    required String jsonString,
    required Future<String> Function() getFilePath,
  }) async {
    wasCalled = true;
    sharedName = name;
    sharedJson = jsonString;
    resolvedFilePath = await getFilePath(); // 실제 경로 호출도 확인 가능
  }
}
