import 'dart:convert';
import 'dart:io';
// import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../../models/project_model.dart';
import '../../models/label_entry.dart';
import '../../models/data_model.dart';
import 'interface_storage_helper.dart';

class StorageHelperImpl implements StorageHelperInterface {
  @override
  Future<String> downloadProjectConfig(Project project) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${project.name}_config.json';
    final file = File(filePath);
    final jsonString = jsonEncode(project.toJson());
    await file.writeAsString(jsonString);
    return filePath;
  }

  @override
  Future<List<Project>> loadProjects() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    await file.writeAsString(projectsJson);
  }

  @override
  Future<List<LabelEntry>> loadLabelEntries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
    await file.writeAsString(labelsJson);
  }

  @override
  Future<String> downloadLabelsAsZip(
    Project project,
    List<LabelEntry> labelEntries,
    List<DataPath> dataPaths, // DataPath를 사용하도록 수정
  ) async {
    final archive = Archive();

    // DataPath에서 데이터 로드 및 ZIP 추가
    for (var dataPath in dataPaths) {
      final content = await dataPath.loadData();
      if (content != null) {
        final fileBytes = utf8.encode(content);
        archive.addFile(
          ArchiveFile(dataPath.fileName, fileBytes.length, fileBytes),
        );
      }
    }

    // JSON 직렬화된 라벨 데이터 추가
    final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
    archive.addFile(
      ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)),
    );

    // ZIP 파일 생성
    final directory = await getApplicationDocumentsDirectory();
    final zipFile = File('${directory.path}/${project.name}_labels.zip');
    final zipData = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipData!);
    return zipFile.path;
  }

  @override
  Future<List<LabelEntry>> importLabelEntries() async {
    // FilePicker 사용 가능
    throw UnimplementedError("Implement import for native.");
  }
}
