// // 📄 lib/src/web_interop/share_helper_interop.dart
// library share_helper_interop;

// import 'dart:js_interop';
// import 'dart:js_interop_unsafe'; // JS export 등록용

// @JS('navigator')
// external Navigator get navigator;

// @JS()
// @staticInterop
// class Navigator {}

// extension NavigatorShare on Navigator {
//   external JSPromise share(ShareData data);
//   external bool canShare(ShareData data);
// }

// @JS()
// @staticInterop
// class ShareData {
//   external factory ShareData({String? title, String? text, String? url});
// }
