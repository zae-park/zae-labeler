// lib/src/platform_helpers/pickers/data_info_picker_io.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'data_info_picker_interface.dart';

class PlatformDataInfoPicker implements DataInfoPicker {
  @override
  Future<List<DataInfo>> pick() async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return const [];

    final dir = Directory(dirPath);
    final files = dir.listSync().whereType<File>();

    final List<DataInfo> out = [];
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      out.add(DataInfo.create(fileName: name, filePath: f.path));
    }
    return out;
  }
}
