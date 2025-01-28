// lib/src/models/project_model.dart

/*
이 파일은 프로젝트 모델을 정의하며, 프로젝트의 주요 정보와 라벨 엔트리 관리를 위한 메서드를 제공합니다.
Project 클래스는 프로젝트 ID, 이름, 라벨링 모드, 클래스 목록, 데이터 경로 등을 포함합니다.
라벨 엔트리를 로드하고 JSON 형식으로 변환하거나 역직렬화할 수 있는 기능도 포함되어 있습니다.
*/

import 'dart:convert';

import './data_model.dart';
import './label_entry.dart';

// 라벨링 모드 열거형
enum LabelingMode { singleClassification, multiClassification, segmentation }

/// Represents a project with its metadata and data paths.
class Project {
  String id; // 프로젝트 고유 ID
  String name; // 프로젝트 이름
  LabelingMode mode; // 라벨링 모드
  List<String> classes; // 설정된 클래스 목록
  List<DataPath> dataPaths; // Web과 Native 모두 지원하는 데이터 경로
  List<LabelEntry> labelEntries; // 라벨 엔트리 관리
  bool isDataLoaded; // 데이터 로드 상태 플래그

  Project({
    required this.id,
    required this.name,
    required this.mode,
    required this.classes,
    this.dataPaths = const [],
    this.labelEntries = const [],
    this.isDataLoaded = false,
  });

  /// Loads label entries from the associated data paths.
  Future<List<LabelEntry>> loadLabelEntries() async {
    final List<LabelEntry> labelEntries = [];
    for (final dataPath in dataPaths) {
      final content = await dataPath.loadData();
      if (content != null) {
        final entries = _parseLabelEntriesFromJson(content);
        labelEntries.addAll(entries);
      }
    }
    return labelEntries;
  }

  /// Parses label entries from a JSON string.
  List<LabelEntry> _parseLabelEntriesFromJson(String jsonContent) {
    final jsonData = jsonDecode(jsonContent) as List<dynamic>;
    return jsonData.map((e) => LabelEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Creates a Project instance from a JSON-compatible map.
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        mode: LabelingMode.values.firstWhere((e) => e.toString().contains(json['mode'])),
        classes: List<String>.from(json['classes']),
        dataPaths: (json['dataPaths'] as List).map((e) => DataPath.fromJson(e)).toList(),
        labelEntries: (json['labelEntries'] as List).map((e) => LabelEntry.fromJson(e)).toList(),
        isDataLoaded: json['isDataLoaded'] ?? false,
      );

  /// Converts the Project instance into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.toString().split('.').last,
        'classes': classes,
        'dataPaths': dataPaths.map((e) => e.toJson()).toList(),
        'labelEntries': labelEntries.map((e) => e.toJson()).toList(),
        'isDataLoaded': isDataLoaded,
      };
}
