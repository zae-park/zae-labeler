// lib/src/utils/web_storage_helper.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import '../../models/project_model.dart';
import '../../models/label_entry.dart';
import 'platform_storage_helper.dart';

class StorageHelperImpl implements PlatformStorageHelper {
  @override
  Future<String> downloadProjectConfig(Project project) async {
    final jsonString = jsonEncode(project.toJson());
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_config.json")
      ..click();
    html.Url.revokeObjectUrl(url);
    return "${project.name}_config.json (downloaded in browser)";
  }

  @override
  Future<List<Project>> loadProjects() async {
    final projectsJson = html.window.localStorage['projects'];
    if (projectsJson != null) {
      List<dynamic> jsonData = jsonDecode(projectsJson);
      return jsonData.map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    html.window.localStorage['projects'] = projectsJson;
  }

  @override
  Future<List<LabelEntry>> loadLabelEntries() async {
    final labelsJson = html.window.localStorage['labels'];
    if (labelsJson != null) {
      List<dynamic> jsonData = jsonDecode(labelsJson);
      return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
    html.window.localStorage['labels'] = labelsJson;
  }

  @override
  Future<String> downloadLabelsAsZip(Project project,
      List<LabelEntry> labelEntries, List<File> dataFiles) async {
    // 웹 환경에서는 File API를 사용할 수 없음
    throw UnimplementedError("File download not supported in web.");
  }

  @override
  Future<List<LabelEntry>> importLabelEntries() async {
    // 웹 환경에서는 FilePicker를 사용할 수 없음
    throw UnimplementedError("File import not supported in web.");
  }
}
