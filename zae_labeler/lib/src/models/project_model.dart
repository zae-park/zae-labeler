// lib/src/models/project_model.dart
import 'dart:convert';

import './data_model.dart';
import './label_model.dart';
import '../utils/storage_helper.dart';

/*
이 파일은 프로젝트 모델을 정의하며, 프로젝트의 주요 정보와 라벨 데이터를 관리하는 기능을 포함합니다.
Project 클래스는 프로젝트 ID, 이름, 라벨링 모드, 클래스 목록, 데이터 경로 등을 저장하며,
라벨 데이터를 `LabelModel`을 기반으로 로드하고 JSON 형식으로 변환할 수 있습니다.
*/

/// ✅ 프로젝트 정보를 저장하는 클래스
class Project {
  final String id; // 프로젝트 고유 ID
  final String name; // 프로젝트 이름
  final LabelingMode mode; // 라벨링 모드
  final List<String> classes; // 설정된 클래스 목록
  final List<DataPath> dataPaths; // 데이터 경로
  List<LabelModel> labels; // ✅ 라벨 데이터 관리

  Project({
    required this.id,
    required this.name,
    required this.mode,
    required this.classes,
    this.dataPaths = const [],
    this.labels = const [], // ✅ 라벨 데이터를 `LabelModel` 기반으로 관리
  });

  // ==============================
  // 📌 **프로젝트 정보 관리**
  // ==============================

  /// ✅ 테스트 및 초기화용 빈 프로젝트 생성자
  factory Project.empty() => Project(id: 'empty', name: '', mode: LabelingMode.singleClassification, classes: const []);

  /// ✅ 프로젝트 복사본을 생성하는 `copyWith` 메소드
  Project copyWith({String? id, String? name, LabelingMode? mode, List<String>? classes, List<DataPath>? dataPaths, List<LabelModel>? labels}) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      classes: classes ?? List.from(this.classes),
      dataPaths: dataPaths ?? List.from(this.dataPaths),
      labels: labels ?? List.from(this.labels),
    );
  }

  /// ✅ 모든 라벨 초기화
  void clearLabels() {
    labels.clear();
  }

  // ==============================
  // 📌 **JSON 변환**
  // ==============================

  /// ✅ JSON 데이터를 기반으로 `Project` 객체 생성
  factory Project.fromJson(Map<String, dynamic> json) {
    final mode = LabelingMode.values.firstWhere((e) => e.toString().split('.').last == json['mode']);
    return Project(
      id: json['id'],
      name: json['name'],
      mode: mode,
      classes: List<String>.from(json['classes']),
      dataPaths: (json['dataPaths'] as List).map((e) => DataPath.fromJson(e)).toList(),
      labels: (json['label'] as List?)?.map((e) => LabelModelConverter.fromJson(mode, e)).toList() ?? [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// ✅ `Project` 객체를 JSON 형식으로 변환
  Map<String, dynamic> toJson({bool includeLabels = true}) {
    final map = {
      'id': id,
      'name': name,
      'mode': mode.toString().split('.').last,
      'classes': classes,
      'dataPaths': dataPaths.map((e) => e.toJson()).toList(),
    };

    if (includeLabels) {
      map['label'] = labels.map((e) => LabelModelConverter.toJson(e)).toList();
    }

    return map;
  }
}
