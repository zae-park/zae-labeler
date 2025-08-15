import '../../../core/models/data/data_info.dart';

/// DataInfo → 원문(String 또는 base64) 로드 인터페이스
abstract class DataLoader {
  Future<String?> loadRaw(DataInfo info);
}
