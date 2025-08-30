// lib/src/platform_helpers/pickers/data_info_picker_io.dart
import 'package:firebase_auth/firebase_auth.dart'; // 시그니처 맞춤(사용 안함)
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart' as mime;

import '../../core/models/data/data_info.dart';
import 'data_info_picker_interface.dart';

class PlatformDataInfoPicker implements DataInfoPicker {
  // 시그니처 통일(웹/IO 동일 생성자)
  PlatformDataInfoPicker({required FirebaseAuth auth});

  @override
  Future<List<DataInfo>> pick() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res == null) return const [];

    final out = <DataInfo>[];
    for (final f in res.files) {
      final path = f.path;
      if (path == null) continue;

      final fileName = DataInfo.fromPath(path).fileName;
      final ct = mime.lookupMimeType(path) ?? 'application/octet-stream';

      out.add(DataInfo.create(fileName: fileName, filePath: path, mimeType: ct, base64Content: null, objectUrl: null));
    }
    return out;
  }
}
