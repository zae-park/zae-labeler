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
  // Project IO
  @override
  Future<void> saveProjects(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    await file.writeAsString(projectsJson);
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
  Future<String> downloadProjectConfig(Project project) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${project.name}_config.json';
    final file = File(filePath);
    final jsonString = jsonEncode(project.toJson());
    await file.writeAsString(jsonString);
    return filePath;
  }

  // Project IO //

  // LabelEntries IO

  // @override
  // Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File('${directory.path}/labels.json');
  //   final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
  //   await file.writeAsString(labelsJson);
  // }

  @override
  Future<void> saveLabelEntries(String projectId, List<LabelEntry> newEntries) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');

    List<LabelEntry> existingEntries = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      existingEntries = (jsonData as List).map((e) => LabelEntry.fromJson(e)).toList();
    }

    // ✅ 기존 라벨 데이터 중 동일한 dataPath를 가진 항목을 새로운 데이터로 업데이트
    for (var newEntry in newEntries) {
      int index = existingEntries.indexWhere((entry) => entry.dataPath == newEntry.dataPath);
      if (index != -1) {
        existingEntries[index] = newEntry;
      } else {
        existingEntries.add(newEntry);
      }
    }

    // ✅ 변경된 데이터만 저장
    final updatedLabelsJson = jsonEncode(existingEntries.map((e) => e.toJson()).toList());
    await file.writeAsString(updatedLabelsJson);
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

  // LabelEntries IO //

  // LabelEntry IO //

  @override
  Future<void> saveLabelEntry(LabelEntry newEntry) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');

    List<LabelEntry> existingEntries = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      existingEntries = (jsonData as List).map((e) => LabelEntry.fromJson(e)).toList();
    }

    int index = existingEntries.indexWhere((entry) => entry.dataPath == newEntry.dataPath);
    if (index != -1) {
      existingEntries[index] = newEntry;
    } else {
      existingEntries.add(newEntry);
    }

    await file.writeAsString(jsonEncode(existingEntries.map((e) => e.toJson()).toList()));
  }

  @override
  Future<LabelEntry> loadLabelEntry(String dataPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      final entries = (jsonData as List).map((e) => LabelEntry.fromJson(e)).toList();
      return entries.firstWhere((entry) => entry.dataPath == dataPath, orElse: () => LabelEntry.empty());
    }
    return LabelEntry.empty();
  }
  // LabelEntry IO //
}
