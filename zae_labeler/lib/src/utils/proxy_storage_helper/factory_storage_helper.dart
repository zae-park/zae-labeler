import 'interface_storage_helper.dart';
import 'native_storage_helper.dart';
import 'web_storage_helper.dart';

PlatformStorageHelper createPlatformHelper() {
  return const bool.fromEnvironment('dart.library.html', defaultValue: false)
      ? WebStorageHelper()
      : NativeStorageHelper();
}
