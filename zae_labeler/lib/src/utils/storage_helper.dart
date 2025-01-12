// lib/src/utils/storage_helper.dart
import 'package:zae_labeler/src/models/data_model.dart';

import '../models/label_entry.dart';
import '../models/project_model.dart';
import 'proxy_storage_helper/platform_storage_helper.dart';
import 'proxy_storage_helper/native_storage_helper.dart' if (dart.library.html) 'proxy_storage_helper/web_storage_helper.dart';

class StorageHelper extends PlatformStorageHelper {
  static final _instance = StorageHelperImpl();

  static PlatformStorageHelper get instance => _instance;

  @override
  Future<String> downloadProjectConfig(Project project) => _instance.downloadProjectConfig(project);

  @override
  Future<List<Project>> loadProjects() => _instance.loadProjects();

  @override
  Future<void> saveProjects(List<Project> projects) => _instance.saveProjects(projects);

  @override
  Future<List<LabelEntry>> loadLabelEntries() => _instance.loadLabelEntries();

  @override
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries) => _instance.saveLabelEntries(labelEntries);

  @override
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<FileData> fileDataList) =>
      _instance.downloadLabelsAsZip(project, labelEntries, fileDataList);

  @override
  Future<List<LabelEntry>> importLabelEntries() => _instance.importLabelEntries();
}
