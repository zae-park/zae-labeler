// lib/src/utils/storage_helper.dart
// export 'proxy_storage_helper/native_storage_helper.dart'
//     if (dart.library.html) 'proxy_storage_helper/web_storage_helper.dart';

import 'dart:io';

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
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<FileData> dataFiles) =>
      _instance.downloadLabelsAsZip(project, labelEntries, dataFiles);

  @override
  Future<List<LabelEntry>> importLabelEntries() => _instance.importLabelEntries();
}


// // lib/src/utils/storage_helper.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:archive/archive.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:html' as html;

// import '../models/project_model.dart';
// import '../models/label_entry.dart';

// class StorageHelper {
//   // 프로젝트 설정 파일 다운로드
//   static Future<String> downloadProjectConfig(Project project) async {
//     // 플랫폼별로 디렉토리 설정
//     Directory directory;
//     if (Platform.isAndroid) {
//       // Android: Downloads 디렉토리
//       final dirs =
//           await getExternalStorageDirectories(type: StorageDirectory.downloads);
//       if (dirs == null || dirs.isEmpty) {
//         throw Exception('다운로드 디렉토리를 찾을 수 없습니다.');
//       }
//       directory = dirs.first;
//     } else if (Platform.isIOS) {
//       // iOS: 애플리케이션 문서 디렉토리
//       directory = await getApplicationDocumentsDirectory();
//     } else if (Platform.isWindows) {
//       // Windows: Downloads 디렉토리
//       final downloadsDirectory = await getDownloadsDirectory();
//       if (downloadsDirectory == null) {
//         throw Exception('Downloads 디렉토리를 찾을 수 없습니다.');
//       }
//       directory = downloadsDirectory;
//     } else {
//       throw UnsupportedError('지원하지 않는 플랫폼입니다.');
//     }

//     // 파일 경로 설정
//     String filePath;
//     if (Platform.isWindows) {
//       filePath = '${directory.path}\\${project.name}_config.json';
//     } else {
//       filePath = '${directory.path}/${project.name}_config.json';
//     }
//     File file = File(filePath);

//     // 프로젝트를 JSON으로 변환하여 파일에 저장
//     String jsonString = jsonEncode(project.toJson());
//     await file.writeAsString(jsonString);

//     return filePath;
//   }

//   /// Load all projects from storage.
//   static Future<List<Project>> loadProjects() async {
//     if (kIsWeb) {
//       final projectsJson = html.window.localStorage['projects'];
//       if (projectsJson != null) {
//         List<dynamic> jsonData = jsonDecode(projectsJson);
//         return jsonData.map((e) => Project.fromJson(e)).toList();
//       }
//       return [];
//     } else {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/projects.json');

//       if (await file.exists()) {
//         String content = await file.readAsString();
//         List<dynamic> jsonData = jsonDecode(content);
//         return jsonData.map((e) => Project.fromJson(e)).toList();
//       }
//       return [];
//     }
//   }

//   /// Save all projects to storage.
//   static Future<void> saveProjects(List<Project> projects) async {
//     final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());

//     if (kIsWeb) {
//       html.window.localStorage['projects'] = projectsJson;
//     } else {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/projects.json');
//       await file.writeAsString(projectsJson);
//     }
//   }

//   /// Load all label entries from storage.
//   Future<List<LabelEntry>> loadLabelEntries() async {
//     if (kIsWeb) {
//       final labelsJson = html.window.localStorage['labels'];
//       if (labelsJson != null) {
//         List<dynamic> jsonData = jsonDecode(labelsJson);
//         return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
//       }
//       return [];
//     } else {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/labels.json');

//       if (await file.exists()) {
//         String content = await file.readAsString();
//         List<dynamic> jsonData = jsonDecode(content);
//         return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
//       }
//       return [];
//     }
//   }

//   /// Save all label entries to storage.
//   Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
//     final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());

//     if (kIsWeb) {
//       html.window.localStorage['labels'] = labelsJson;
//     } else {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/labels.json');
//       await file.writeAsString(labelsJson);
//     }
//   }

//   Future<String> downloadLabelsAsZip(Project project,
//       List<LabelEntry> labelEntries, List<File> dataFiles) async {
//     final archive = Archive();

//     // Add data files to archive
//     for (var file in dataFiles) {
//       if (await file.exists()) {
//         final fileBytes = await file.readAsBytes();
//         archive.addFile(ArchiveFile(
//           path.basename(file.path),
//           fileBytes.length,
//           fileBytes,
//         ));
//       }
//     }

//     // Add labels.json to archive
//     final labelsJson = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
//     archive.addFile(
//         ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

//     final zipData = ZipEncoder().encode(archive);
//     if (zipData == null) {
//       throw Exception('Failed to create ZIP archive.');
//     }

//     if (kIsWeb) {
//       // For web, trigger download in the browser
//       final blob = html.Blob([zipData]);
//       final url = html.Url.createObjectUrlFromBlob(blob);
//       final anchor = html.AnchorElement(href: url)
//         ..setAttribute("download", "${project.name}_labels.zip")
//         ..click();
//       html.Url.revokeObjectUrl(url);
//       return "${project.name}_labels.zip (web download)"; // Web doesn't have a physical file path
//     } else {
//       // For mobile/desktop, save ZIP file to a directory
//       final directory = await getApplicationDocumentsDirectory();
//       final zipFile = File('${directory.path}/${project.name}_labels.zip');
//       await zipFile.writeAsBytes(zipData);
//       return zipFile.path; // Return the file path
//     }
//   }

//   /// Import labels from a JSON or ZIP file.
//   Future<List<LabelEntry>> importLabelEntries() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['json', 'zip'],
//     );

//     if (result != null) {
//       final filePath = result.files.single.path;
//       if (filePath != null) {
//         final file = File(filePath);

//         if (path.extension(filePath) == '.json') {
//           final content = await file.readAsString();
//           List<dynamic> jsonData = jsonDecode(content);
//           return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
//         } else if (path.extension(filePath) == '.zip') {
//           final bytes = await file.readAsBytes();
//           final archive = ZipDecoder().decodeBytes(bytes);

//           for (final archiveFile in archive) {
//             if (archiveFile.name == 'labels.json') {
//               final jsonString = utf8.decode(archiveFile.content);
//               List<dynamic> jsonData = jsonDecode(jsonString);
//               return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
//             }
//           }
//         }
//       }
//     }

//     throw Exception('No valid file selected or failed to import.');
//   }
// }

// // TODO: 플랫폼에 따라 구현체 분리
// // https://chtgupta.medium.com/stop-using-kisweb-the-right-way-to-implement-multi-platform-code-in-your-flutter-project-edcd67970aa3