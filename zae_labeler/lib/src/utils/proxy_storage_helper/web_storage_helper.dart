// lib/src/utils/web_storage_helper.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:archive/archive.dart'; // ZIP 압축 라이브러리

import '../../models/project_model.dart';
import '../../models/label_entry.dart';
import 'interface_storage_helper.dart';

class StorageHelperImpl implements StorageHelperInterface {
  // Project IO
  @override
  Future<void> saveProjects(List<Project> projects) async {
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    html.window.localStorage['projects'] = projectsJson;
  }

  @override
  Future<List<Project>> loadProjects() async {
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
  // Project IO //

  // LabelEntries IO

  // @override
  // Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
  //   final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
  //   html.window.localStorage['labels'] = labelsJson;
  // }

  @override
  Future<void> saveLabelEntries(List<LabelEntry> newEntries) async {
    // 새 LabelEntries 만 저장
    final labelsJson = html.window.localStorage['labels'];

    List<LabelEntry> existingEntries = [];
    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
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
    html.window.localStorage['labels'] = updatedLabelsJson;
  }

  @override
  Future<List<LabelEntry>> loadLabelEntries() async {
    final labelsJson = html.window.localStorage['labels'];
    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      return (jsonData as List).map((e) => LabelEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<String> downloadLabelsAsZip(
    Project project,
    List<LabelEntry> labelEntries,
    List<DataPath> dataPaths, // 수정된 파라미터
  ) async {
    final archive = Archive();

    for (var dataPath in dataPaths) {
      final content = await dataPath.loadData(); // DataPath에서 데이터 로드
      if (content != null) {
        final fileBytes = utf8.encode(content);
        archive.addFile(ArchiveFile(dataPath.fileName, fileBytes.length, fileBytes));
      }
    }

    // JSON 직렬화한 라벨 데이터 추가
    final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
    archive.addFile(ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

    // ZIP 파일 생성
    final zipData = ZipEncoder().encode(archive);

    // Blob 생성 및 다운로드 링크 구성
    final blob = html.Blob([Uint8List.fromList(zipData!)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_labels.zip")
      ..click();
    html.Url.revokeObjectUrl(url);

    return "${project.name}_labels.zip (downloaded in browser)";
  }

  @override
  Future<List<LabelEntry>> importLabelEntries() async {
    final completer = Completer<List<LabelEntry>>();

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
              final entries = jsonData.map((e) => LabelEntry.fromJson(e as Map<String, dynamic>)).toList();
              completer.complete(entries);
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

  // LabelEntries IO //

  // LabelEntry IO

  @override
  Future<void> saveLabelEntry(LabelEntry newEntry) async {
    final labelsJson = html.window.localStorage['labels'];
    List<LabelEntry> existingEntries = [];

    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      existingEntries = (jsonData as List).map((e) => LabelEntry.fromJson(e)).toList();
    }

    int index = existingEntries.indexWhere((entry) => entry.dataPath == newEntry.dataPath);
    if (index != -1) {
      existingEntries[index] = newEntry;
    } else {
      existingEntries.add(newEntry);
    }

    html.window.localStorage['labels'] = jsonEncode(existingEntries.map((e) => e.toJson()).toList());
  }

  @override
  Future<LabelEntry?> loadLabelEntry(String dataPath) async {
    final labelsJson = html.window.localStorage['labels'];
    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      final entries = (jsonData as List).map((e) => LabelEntry.fromJson(e)).toList();
      return entries.firstWhere((entry) => entry.dataPath == dataPath, orElse: () => LabelEntry.empty());
    }
    return null;
  }

  // LabelEntry IO //
}
