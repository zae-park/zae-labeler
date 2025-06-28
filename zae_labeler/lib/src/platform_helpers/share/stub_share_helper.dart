import 'interface_share_helper.dart';

class ShareHelperImpl implements ShareHelperInterface {
  @override
  Future<void> shareProject({required String name, required String jsonString, required Future<String> Function() getFilePath}) async {
    throw UnsupportedError('Sharing not supported on this platform');
  }
}
