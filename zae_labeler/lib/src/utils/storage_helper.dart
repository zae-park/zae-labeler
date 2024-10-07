// lib/src/utils/storage_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project_model.dart';
import '../models/label_model.dart';
import '../models/label_entry.dart';

class StorageHelper {
  static const String projectsKey = 'projects';
  static const String labelsKey = 'labels';

  // 프로젝트 설정 파일 다운로드
  static Future<String> downloadProjectConfig(Project project) async {
    // 플랫폼별로 디렉토리 설정
    Directory directory;
    if (Platform.isAndroid) {
      // Android: Downloads 디렉토리
      final dirs =
          await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (dirs == null || dirs.isEmpty) {
        throw Exception('다운로드 디렉토리를 찾을 수 없습니다.');
      }
      directory = dirs.first;
    } else if (Platform.isIOS) {
      // iOS: 애플리케이션 문서 디렉토리
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      // Windows: Downloads 디렉토리
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        throw Exception('Downloads 디렉토리를 찾을 수 없습니다.');
      }
      directory = downloadsDirectory;
    } else {
      throw UnsupportedError('지원하지 않는 플랫폼입니다.');
    }

    // 파일 경로 설정
    String filePath = '${directory.path}\\${project.name}_config.json';
    File file = File(filePath);

    // 프로젝트를 JSON으로 변환하여 파일에 저장
    String jsonString = jsonEncode(project.toJson());
    await file.writeAsString(jsonString);

    return filePath;
  }

  // 프로젝트 저장
  static Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> projectsJson =
        projects.map((project) => jsonEncode(project.toJson())).toList();
    await prefs.setStringList(projectsKey, projectsJson);
  }

  // 프로젝트 불러오기
  static Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? projectsJson = prefs.getStringList(projectsKey);
    if (projectsJson == null) return [];
    return projectsJson
        .map((projectStr) =>
            Project.fromJson(jsonDecode(projectStr) as Map<String, dynamic>))
        .toList();
  }

  // 라벨 저장
  static Future<void> saveLabels(List<Label> labels) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> labelsJson =
        labels.map((label) => jsonEncode(label.toJson())).toList();
    await prefs.setStringList(labelsKey, labelsJson);
  }

  // 라벨 불러오기
  static Future<List<Label>> loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? labelsJson = prefs.getStringList(labelsKey);
    if (labelsJson == null) return [];
    return labelsJson
        .map((labelStr) =>
            Label.fromJson(jsonDecode(labelStr) as Map<String, dynamic>))
        .toList();
  }

  // 라벨 Entry 불러오기
  static Future<List<LabelEntry>> loadLabelEntries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // 라벨 Entry 저장하기
  static Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    List<Map<String, dynamic>> jsonData =
        labelEntries.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }
}
