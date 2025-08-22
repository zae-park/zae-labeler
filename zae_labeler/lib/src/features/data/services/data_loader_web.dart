// lib/src/features/data/services/data_loader_web.dart
import 'package:path/path.dart' as p;
// 웹에선 File I/O가 없으므로 네트워크/메모리 소스만 다룬다고 가정

import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

import 'data_loader_interface.dart';

class WebDataLoader implements DataLoader {
  @override
  Future<UnifiedData> fromDataInfo(DataInfo info) async {
    // Web에서는 보통:
    // 1) info.filePath가 http(s) URL 이거나
    // 2) Firebase Storage/DB에서 직접 읽어오도록 상위에서 이미 base64/JSON을 주입
    //
    // 여기서는 보수적으로 “이미 상위에서 objectData/imageBase64를 채워둔 DataInfo”라고 가정하거나,
    // 경로가 있더라도 네트워크 fetch는 하지 않고 최소 객체만 반환합니다.
    final ext = p.extension(info.fileName).toLowerCase();
    if (ext == '.csv') {
      // CSV는 웹 fetch 없이 unsupported 처리(필요시 별도 fetch 로직 추가)
      return UnifiedData(dataInfo: info, fileType: FileType.series);
    } else if (ext == '.json') {
      return UnifiedData(dataInfo: info, fileType: FileType.object);
    } else {
      return UnifiedData(dataInfo: info, fileType: FileType.image);
    }
  }
}

/// data_loader.dart의 조건부 import에서 호출
DataLoader createDataLoader() => WebDataLoader();
