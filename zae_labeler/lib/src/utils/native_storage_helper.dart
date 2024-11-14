import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../models/project_model.dart';
import '../models/label_entry.dart';
import 'platform_storage_helper.dart';

class NativeStorageHelper implements PlatformStorageHelper {
  @override
  Future<List<Project>> loadProjects() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    await file
        .writeAsString(jsonEncode(projects.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<LabelEntry>> loadLabelEntries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    await file.writeAsString(
        jsonEncode(labelEntries.map((e) => e.toJson()).toList()));
  }

  @override
  Future<String> downloadLabelsAsZip(Project project,
      List<LabelEntry> labelEntries, List<dynamic> dataFiles) async {
    final archive = Archive();

    for (var file in dataFiles) {
      if (file is File && await file.exists()) {
        final fileBytes = await file.readAsBytes();
        archive.addFile(
            ArchiveFile(path.basename(file.path), fileBytes.length, fileBytes));
      }
    }

    final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
    archive.addFile(
        ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to create ZIP archive.');

    final directory = await getApplicationDocumentsDirectory();
    final zipFile = File('${directory.path}/${project.name}_labels.zip');
    await zipFile.writeAsBytes(zipData);

    return zipFile.path;
  }
}
