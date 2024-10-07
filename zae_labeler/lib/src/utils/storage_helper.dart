// lib/src/utils/storage_helper.dart
import 'dart:convert';
import 'dart:io';
import '../models/project_model.dart';
import '../models/label_entry.dart';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  // 기존 메서드들...

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
    String filePath;
    if (Platform.isWindows) {
      filePath = '${directory.path}\\${project.name}_config.json';
    } else {
      filePath = '${directory.path}/${project.name}_config.json';
    }
    File file = File(filePath);

    // 프로젝트를 JSON으로 변환하여 파일에 저장
    String jsonString = jsonEncode(project.toJson());
    await file.writeAsString(jsonString);

    return filePath;
  }

  // 기존 메서드들...

  // 프로젝트 목록 로드 및 저장 메서드 (이미 구현되어 있을 경우 생략 가능)
  static Future<List<Project>> loadProjects() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => Project.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  static Future<void> saveProjects(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    List<Map<String, dynamic>> jsonData =
        projects.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  // 라벨 엔트리 로드 및 저장 메서드 (이미 구현되어 있을 경우 생략 가능)
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

  static Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    List<Map<String, dynamic>> jsonData =
        labelEntries.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }
}
