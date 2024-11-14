// lib/src/utils/platform_storage_helper.dart
import 'native_storage_helper.dart'
    if (dart.library.html) 'web_storage_helper.dart';
import '../models/project_model.dart';
import '../models/label_entry.dart';

abstract class PlatformStorageHelper {
  Future<List<Project>> loadProjects();
  Future<void> saveProjects(List<Project> projects);
  Future<List<LabelEntry>> loadLabelEntries();
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries);
  Future<void> downloadLabelsAsZip(
      Project project, List<LabelEntry> labelEntries, List<dynamic> dataFiles);
  Future<List<LabelEntry>> importLabelEntries();
}

// 싱글톤 인스턴스 관리
PlatformStorageHelper? _helperInstance;

PlatformStorageHelper get storageHelper {
  _helperInstance ??= createPlatformHelper();
  return _helperInstance!;
}

PlatformStorageHelper createPlatformHelper() {
  if (const bool.fromEnvironment('dart.library.html', defaultValue: false)) {
    return WebStorageHelper();
  } else {
    return NativeStorageHelper();
  }
}
