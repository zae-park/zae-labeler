// lib/src/utils/storage_helper.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../models/label_model.dart';

class StorageHelper {
  static const String projectsKey = 'projects';
  static const String labelsKey = 'labels';

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
    return labelsJson
        .map((labelStr) =>
            Label.fromJson(jsonDecode(labelStr) as Map<String, dynamic>))
        .toList();
  }
}
