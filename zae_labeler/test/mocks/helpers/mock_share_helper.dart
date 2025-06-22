import 'package:zae_labeler/src/utils/proxy_share_helper/interface_share_helper.dart';

/// 🧪 테스트용 MockShareHelper
class MockShareHelper implements ShareHelperInterface {
  bool wasCalled = false;
  String? sharedName;
  String? sharedJson;
  late Future<String> Function() sharedFilePathGetter;

  @override
  Future<void> shareProject({required String name, required String jsonString, required Future<String> Function() getFilePath}) async {
    wasCalled = true;
    sharedName = name;
    sharedJson = jsonString;
    sharedFilePathGetter = getFilePath;
  }
}
