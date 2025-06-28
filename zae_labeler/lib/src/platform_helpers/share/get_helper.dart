import 'interface_share_helper.dart';
import 'stub_share_helper.dart'
    if (dart.library.html) 'web_share_helper.dart'
    if (dart.library.io) 'native_share_helper.dart'
    if (dart.library.js) 'web_share_helper.dart' // fallback for web
    if (dart.library.ffi) 'native_share_helper.dart'
    if (dart.library.isolate) 'native_share_helper.dart'
    if (dart.library.mirrors) 'stub_share_helper.dart'; // fallback

ShareHelperInterface getShareHelper() => ShareHelperImpl(); // ShareHelperImpl은 각 platform에서 구현됨
