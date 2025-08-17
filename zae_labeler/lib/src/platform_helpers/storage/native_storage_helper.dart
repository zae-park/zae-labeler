import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'interface_storage_helper.dart';
import '../../core/models/data/data_info.dart';
import '../../features/label/models/label_model.dart';
import '../../core/models/project/project_model.dart';

class StorageHelperImpl implements StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    await file.writeAsString(projectsJson);
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
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

  // ==============================
  // 📌 **Project List Management**
  // ==============================

  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');

    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    await file.writeAsString(projectsJson); // ✅ 프로젝트 리스트를 JSON 파일로 저장
  }

  @override
  Future<List<Project>> loadProjectList() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      return (jsonData as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    List<Map<String, dynamic>> existingEntries = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      existingEntries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
    }

    // ✅ `LabelModel`을 JSON으로 변환
    Map<String, dynamic> labelEntry = {
      'data_id': dataId,
      'data_path': dataPath,
      'mode': labelModel.mode.toString(),
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'label_data': LabelModelConverter.toJson(labelModel),
    };

    int index = existingEntries.indexWhere((entry) => entry['data_id'] == dataId);
    if (index != -1) {
      existingEntries[index] = labelEntry;
    } else {
      existingEntries.add(labelEntry);
    }

    await file.writeAsString(jsonEncode(existingEntries));
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      final entries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, dynamic>? labelEntry = entries.firstWhere((entry) => entry['data_id'] == dataId, orElse: () => {});

      if (labelEntry.isNotEmpty) {
        return LabelModelConverter.fromJson(mode, labelEntry['label_data']);
      }
    }
    return LabelModelConverter.fromJson(mode, {});
  }

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================

  // Entire LabelModel IO
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    // ✅ LabelModel을 JSON으로 변환 후 저장
    List<Map<String, dynamic>> labelEntries = labels
        .map((label) => {
              'mode': label.mode.toString(),
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': LabelModelConverter.toJson(label),
            })
        .toList();

    // await file.writeAsString(jsonEncode(labelEntries));
    await file.writeAsString(utf8.decode(utf8.encode(jsonEncode(labelEntries))));
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      return (jsonData as List).map((entry) {
        final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
        return LabelModelConverter.fromJson(mode, entry['label_data']);
      }).toList();
    }
    return [];
  }

  @override
  Future<void> deleteProjectLabels(String projectId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    if (await file.exists()) {
      await file.delete(); // ✅ 파일 삭제
    }
  }

  /// 📌 [deleteProject]
  /// 프로젝트 전체를 삭제합니다.
  /// - 내부적으로 `deleteProjectLabels()`를 호출하여 라벨을 먼저 삭제한 뒤,
  ///   프로젝트 문서 자체를 Firestore에서 제거합니다.
  @override
  Future<void> deleteProject(String projectId) async {
    // 1️⃣ 라벨 데이터 삭제 (재사용)
    await deleteProjectLabels(projectId);

    final directory = await getApplicationDocumentsDirectory();
    final file = File(directory.path);

    if (await file.exists()) {
      await file.delete(); // ✅ 파일 삭제
    }
  }

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async {
    final archive = Archive();

    // 1) 원본 파일 추가 (바이트 기준 처리)
    for (final info in fileDataList) {
      List<int>? bytes;

      if (info.filePath != null) {
        final f = File(info.filePath!);
        if (await f.exists()) {
          bytes = await f.readAsBytes(); // ✅ 바이너리 안전
        }
      } else if (info.base64Content != null) {
        final raw = info.base64Content!;
        final b64 = raw.startsWith('data:') ? raw.substring(raw.indexOf(',') + 1) : raw;
        bytes = base64Decode(b64); // ✅ 웹 업로드 base64 대응
      }

      if (bytes != null) {
        final name = info.fileName;
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }

    // 2) labels.json 추가
    final entries = labelModels
        .map((label) => {
              'data_id': label.dataId,
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': LabelModelConverter.toJson(label),
            })
        .toList();

    final labelsJson = jsonEncode(entries);
    archive.addFile(ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

    // 3) zip 생성
    final dir = await getApplicationDocumentsDirectory();
    final zipFile = File(p.join(dir.path, '${project.name}_labels.zip'));
    final zipData = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipData!);
    return zipFile.path;
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_import.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      return (jsonData as List).map((entry) {
        final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
        return LabelModelConverter.fromJson(mode, entry['label_data']);
      }).toList();
    }
    return [];
  }

  // ==============================
  // 📌 **Cache Management**
  // ==============================
  @override
  Future<void> clearAllCache() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();

    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        await file.delete(); // ✅ 모든 JSON 파일 삭제
      }
    }
  }
}
