// lib/src/utils/web_storage_helper.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:archive/archive.dart'; // ZIP 압축 라이브러리

import '../../models/project_model.dart';
import '../../models/label_entry.dart';
import 'platform_storage_helper.dart';

class StorageHelperImpl implements PlatformStorageHelper {
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
  Future<String> downloadLabelsAsZip(
    Project project,
    List<LabelEntry> labelEntries,
    List<FileData> fileDataList,
  ) async {
    final archive = Archive();

    for (var fileData in fileDataList) {
      final fileBytes = base64Decode(fileData.content);
      archive.addFile(ArchiveFile(fileData.name, fileBytes.length, fileBytes));
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

    // 파일 입력 생성
    final input = html.FileUploadInputElement();
    input.accept = '.json'; // JSON 파일만 허용
    input.multiple = false; // 한 번에 하나의 파일만 선택

    // 파일이 선택된 경우
    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsText(files[0]);

        // 파일 읽기가 완료되면 JSON 파싱
        reader.onLoadEnd.listen((event) {
          try {
            final jsonData = jsonDecode(reader.result as String);
            if (jsonData is List) {
              final entries = jsonData.map((e) => LabelEntry.fromJson(e)).toList();
              completer.complete(entries); // 결과 반환
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

    input.click(); // 파일 선택 창 열기

    return completer.future;
  }
}
