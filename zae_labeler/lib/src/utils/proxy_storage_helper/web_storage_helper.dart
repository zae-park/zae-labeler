import 'dart:convert';
import 'dart:html' as html;
import 'package:archive/archive.dart';
import '../../models/project_model.dart';
import '../../models/label_entry.dart';
import 'interface_storage_helper.dart';

class WebStorageHelper implements PlatformStorageHelper {
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
    html.window.localStorage['projects'] =
        jsonEncode(projects.map((e) => e.toJson()).toList());
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
    html.window.localStorage['labels'] =
        jsonEncode(labelEntries.map((e) => e.toJson()).toList());
  }

  @override
  Future<String> downloadLabelsAsZip(Project project,
      List<LabelEntry> labelEntries, List<dynamic> dataFiles) async {
    final archive = Archive();

    for (var file in dataFiles) {
      final fileBytes = file as List<int>;
      archive
          .addFile(ArchiveFile(file.toString(), fileBytes.length, fileBytes));
    }

    final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
    archive.addFile(
        ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to create ZIP archive.');

    final blob = html.Blob([zipData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_labels.zip")
      ..click();
    html.Url.revokeObjectUrl(url);

    return "${project.name}_labels.zip (web download)";
  }
}
