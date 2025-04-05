import './proxy_share_helper/interface_share_helper.dart';
import './proxy_share_helper/stub_share_helper.dart'
    if (dart.library.html) './proxy_share_helper/web_share_helpe.dart'
    if (dart.library.io) './proxy_share_helper/native_share_helper.dart';

ShareHelperInterface getShareHelper() => ShareHelperImpl(); // ShareHelperImpl은 각 platform에서 구현됨
