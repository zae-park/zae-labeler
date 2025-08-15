// 플랫폼/환경별로 DataInfo를 읽어 *원문 문자열*을 반환.
// - 이미지: base64 문자열을 반환 (web base64 그대로 통과 가능)
// - csv/json: 파일 내용을 문자열로 반환
//
// 주의: 실제 구현에서 web은 base64, native는 dart:io를 사용하게 됨.
//       여기서는 인터페이스 + 기본 구현 스텁만 예시.
import '../../../core/models/data/data_info.dart';

abstract class DataLoader {
  Future<String?> loadRaw(DataInfo info);
}

class DefaultDataLoader implements DataLoader {
  @override
  Future<String?> loadRaw(DataInfo info) async {
    // 1) 웹: base64Content 우선
    if (info.base64Content != null) {
      return info.base64Content;
    }
    // 2) 네이티브: filePath 읽기 (실제 구현은 플랫폼별로)
    //    - web 타겟에서는 dart:io를 사용할 수 없으니,
    //      여기는 별도의 플랫폼 분기/conditional import를 적용하는 편이 안전.
    //    - 지금은 스텁으로 null 처리.
    return null;
  }
}
