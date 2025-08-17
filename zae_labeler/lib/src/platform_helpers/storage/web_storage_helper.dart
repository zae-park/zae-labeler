import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:archive/archive.dart';

import 'interface_storage_helper.dart';
import '../../core/models/project/project_model.dart';
import '../../core/models/data/data_info.dart';
import '../../features/label/models/label_model.dart';

class StorageHelperImpl implements StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    html.window.localStorage['projects'] = projectsJson;
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
    final projectsJson = html.window.localStorage['projects'];
    if (projectsJson != null) {
      final jsonData = jsonDecode(projectsJson);
      return (jsonData as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    final jsonString = jsonEncode(project.toJson());
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_config.json")
      ..click();
    html.Url.revokeObjectUrl(url);
    return "${project.name}_config.json (downloaded in browser)";
  }

  // ==============================
  // 📌 **Project List Management**
  // ==============================
  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    html.window.localStorage['projects'] = projectsJson; // ✅ `localStorage`에 저장
  }

  @override
  Future<List<Project>> loadProjectList() async {
    final projectsJson = html.window.localStorage['projects'];

    if (projectsJson != null) {
      final jsonData = jsonDecode(projectsJson);
      return (jsonData as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    final storageKey = 'labels_project_$projectId';
    final labelsJson = html.window.localStorage[storageKey];

    List<Map<String, dynamic>> existingEntries = [];
    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      existingEntries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
    }

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

    html.window.localStorage[storageKey] = jsonEncode(existingEntries);
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    final storageKey = 'labels_project_$projectId';
    final labelsJson = html.window.localStorage[storageKey];

    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      final entries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, dynamic>? labelEntry = entries.firstWhere(
        (entry) => entry['data_id'] == dataId,
        orElse: () => {},
      );

      if (labelEntry.isNotEmpty) {
        return LabelModelConverter.fromJson(mode, labelEntry['label_data']);
      }
    }
    return LabelModelFactory.createNew(mode, dataId: dataId);
  }

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final storageKey = 'labels_project_$projectId';

    List<Map<String, dynamic>> labelEntries = labels
        .map((label) => {
              'mode': label.mode.toString(),
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': LabelModelConverter.toJson(label),
            })
        .toList();

    html.window.localStorage[storageKey] = jsonEncode(labelEntries);
  }

  // ✅ 모든 Label 불러오기
  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    final storageKey = 'labels_project_$projectId';
    final labelsJson = html.window.localStorage[storageKey];

    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      return (jsonData as List).map((entry) {
        final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
        return LabelModelConverter.fromJson(mode, entry['label_data']);
      }).toList();
    }
    return [];
  }

  @override
  Future<void> deleteProjectLabels(String projectId) async {
    final storageKey = 'labels_project_$projectId';
    html.window.localStorage.remove(storageKey); // ✅ localStorage에서 삭제
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await deleteProjectLabels(projectId); // ✅ 라벨 삭제
  }

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async {
    final archive = Archive();

    // 1) 원본 파일(base64) → 바이트로 변환 후 포함
    for (final info in fileDataList) {
      if (info.base64Content == null || info.base64Content!.isEmpty) continue;
      final raw = info.base64Content!;
      final b64 = raw.startsWith('data:') ? raw.substring(raw.indexOf(',') + 1) : raw;
      final bytes = base64Decode(b64);
      archive.addFile(ArchiveFile(info.fileName, bytes.length, bytes));
    }

    // 2) labels.json
    final entries = labelModels
        .map((label) => {
              'data_id': label.dataId,
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': LabelModelConverter.toJson(label),
            })
        .toList();
    final labelsJson = jsonEncode(entries);
    archive.addFile(ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

    // 3) 브라우저 다운로드 트리거
    final zipData = ZipEncoder().encode(archive)!;
    final blob = html.Blob([zipData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', '${project.name}_labels.zip')
      ..click();
    html.Url.revokeObjectUrl(url);
    return '${project.name}_labels.zip (downloaded)';
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    final completer = Completer<List<LabelModel>>();

    final input = html.FileUploadInputElement();
    input.accept = '.json';
    input.multiple = false;

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsText(files[0]);

        reader.onLoadEnd.listen((event) {
          try {
            final jsonData = jsonDecode(reader.result as String);
            if (jsonData is List) {
              final labels = jsonData.map((entry) {
                final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
                return LabelModelConverter.fromJson(mode, entry['label_data']);
              }).toList();
              completer.complete(labels);
            } else {
              throw const FormatException('Invalid JSON format. Expected a list.');
            }
          } catch (e) {
            completer.completeError(e);
          }
        });
        reader.onError.listen((error) => completer.completeError(error));
      } else {
        completer.completeError(Exception('No file selected.'));
      }
    });

    input.click();
    return completer.future;
  }

  // ==============================
  // 📌 **Cache Management**
  // ==============================
  @override
  Future<void> clearAllCache() async {
    html.window.localStorage.clear(); // ✅ localStorage 전체 삭제
  }
}
