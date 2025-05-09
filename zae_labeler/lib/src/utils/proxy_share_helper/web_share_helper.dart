import 'dart:html' as html;

import 'interface_share_helper.dart';

class ShareHelperImpl implements ShareHelperInterface {
  @override
  Future<void> shareProject({
    required String name,
    required String jsonString,
    required Future<String> Function() getFilePath,
  }) async {
    await html.window.navigator.share({'title': name, 'text': jsonString});
  }
}
