// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'interface_share_helper.dart';

class ShareHelperImpl implements ShareHelperInterface {
  @override
  Future<void> shareProject({
    required String name,
    required String jsonString,
    required Future<String> Function() getFilePath,
  }) async {
    try {
      await html.window.navigator.share({'title': name, 'text': jsonString});
      return;
    } catch (e) {
      debugPrint('⚠️ navigator.share failed: $e');
    }

    final blob = html.Blob([jsonString], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "$name.json")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
