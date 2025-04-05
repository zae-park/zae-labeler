import './proxy_share_helper/stub_share_helper.dart';
import './proxy_share_helper/web_share_helper.dart' if (dart.library.io) './proxy_share_helper/native_share_helper.dart';
export './proxy_share_helper/stub_share_helper.dart';

class ShareHelper extends ShareHelperInterface {
  static final _instance = ShareHelperInterface();
  static ShareHelperInterface get instance => _instance;
}
