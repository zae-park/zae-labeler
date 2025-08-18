import 'interface_share_helper.dart';
// 플랫폼별 구현을 하나의 별칭(namespace)로 묶기
import 'stub_share_helper.dart' if (dart.library.html) 'web_share_helper.dart' if (dart.library.io) 'native_share_helper.dart' as platform;

/// 로컬(클라우드 제외)에서 사용할 StorageHelper 구현체 생성
ShareHelperInterface createLocalStorageHelper() => platform.ShareHelperImpl();
