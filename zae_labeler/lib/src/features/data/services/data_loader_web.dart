// 웹에서는 dart:io가 불가하므로 반드시 base64Content에 의존
import 'data_loader_interface.dart';
import '../../../core/models/data/data_info.dart';

class WebDataLoader implements DataLoader {
  @override
  Future<String?> loadRaw(DataInfo info) async {
    return info.base64Content; // 없으면 null
  }
}
