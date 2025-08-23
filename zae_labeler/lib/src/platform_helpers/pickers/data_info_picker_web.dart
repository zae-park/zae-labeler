// lib/src/platform_helpers/pickers/data_info_picker_web.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'data_info_picker_interface.dart';

class PlatformDataInfoPicker implements DataInfoPicker {
  @override
  Future<List<DataInfo>> pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return const [];

    final List<DataInfo> out = [];
    for (final f in result.files) {
      final bytes = f.bytes;
      if (bytes == null) continue;
      final encoded = base64Encode(bytes);
      out.add(DataInfo.create(fileName: f.name, base64Content: encoded));
    }
    return out;
  }
}
