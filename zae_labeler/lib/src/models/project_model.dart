// lib/src/models/project_model.dart
import 'dart:convert';

import './data_model.dart';
import './label_entry.dart';

// 라벨링 모드 열거형
enum LabelingMode { singleClassification, multiClassification, segmentation }

// Project 모델 정의
class Project {
  String id; // 프로젝트 고유 ID
  String name; // 프로젝트 이름
  LabelingMode mode; // 라벨링 모드
  List<String> classes; // 설정된 클래스 목록
  List<DataPath> dataPaths; // Web과 Native 모두 지원하는 데이터 경로

  bool isDataLoaded; // 데이터 로드 상태 플래그

  Project({
    required this.id,
    required this.name,
    required this.mode,
    required this.classes,
    this.dataPaths = const [],
    this.isDataLoaded = false,
  });

  // 라벨 엔트리 로드
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

  // JSON 데이터를 라벨 엔트리로 변환
  List<LabelEntry> _parseLabelEntriesFromJson(String jsonContent) {
    final jsonData = jsonDecode(jsonContent) as List<dynamic>;
    return jsonData.map((e) => LabelEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  // JSON 직렬화 및 역직렬화
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        mode: LabelingMode.values.firstWhere((e) => e.toString().contains(json['mode'])),
        classes: List<String>.from(json['classes']),
        dataPaths: (json['dataPaths'] as List).map((e) => DataPath.fromJson(e)).toList(),
        isDataLoaded: json['isDataLoaded'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.toString().split('.').last,
        'classes': classes,
        'dataPaths': dataPaths.map((e) => e.toJson()).toList(),
        'isDataLoaded': isDataLoaded,
      };
}
