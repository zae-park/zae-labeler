import 'package:share_plus/share_plus.dart';

import '../share_helper.dart';

class MobileShareHelper implements ShareHelperInterface {
  @override
  Future<void> shareProject({
    required String name,
    required String jsonString,
    required Future<String> Function() getFilePath,
  }) async {
    final path = await getFilePath();
    await Share.shareXFiles([XFile(path)], text: '$name project configuration');
  }
}
