// lib/src/platform_helpers/pickers/data_info_picker.dart
import 'data_info_picker_interface.dart';
// 조건부 import로 구현을 별칭(impl)으로 불러옴
import 'data_info_picker_io.dart' if (dart.library.html) 'data_info_picker_web.dart' as impl;

// 외부에 노출할 타입만 export
export 'data_info_picker_interface.dart' show DataInfoPicker;

/// 앱에서 이 팩토리만 부르면 플랫폼별 구현을 돌려줍니다.
DataInfoPicker createDataInfoPicker() => impl.PlatformDataInfoPicker();
