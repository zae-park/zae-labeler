// lib/src/models/project_model.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/models/data/data_model.dart';
import '../../label/models/label_model.dart';
import '../../../platform_helpers/storage/get_storage_helper.dart';

/*
이 파일은 프로젝트 모델을 정의하며, 프로젝트의 주요 정보와 라벨 데이터를 관리하는 기능을 포함합니다.
Project 클래스는 프로젝트 ID, 이름, 라벨링 모드, 클래스 목록, 데이터 경로 등을 저장하며,
라벨 데이터를 `LabelModel`을 기반으로 로드하고 JSON 형식으로 변환할 수 있습니다.
*/

/// ✅ 프로젝트 정보를 저장하는 클래스
class Project extends ChangeNotifier {
  String id; // 프로젝트 고유 ID
  String name; // 프로젝트 이름
  LabelingMode mode; // 라벨링 모드
  List<String> classes; // 설정된 클래스 목록
  List<DataInfo> dataInfos; // 데이터 경로
  List<LabelModel> labels; // ✅ 라벨 데이터 관리

  Project({required this.id, required this.name, required this.mode, required this.classes, this.dataInfos = const [], this.labels = const []});

  /// ✅ 테스트 및 초기화용 빈 프로젝트 생성자
  factory Project.empty() => Project(id: 'empty', name: '', mode: LabelingMode.singleClassification, classes: const []);

  /// ✅ 프로젝트 복사본을 생성하는 `copyWith` 메소드
  Project copyWith({String? id, String? name, LabelingMode? mode, List<String>? classes, List<DataInfo>? dataInfos, List<LabelModel>? labels}) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      classes: classes ?? List.from(this.classes),
      dataInfos: dataInfos ?? List.from(this.dataInfos),
      labels: labels ?? List.from(this.labels),
    );
  }

  void updateName(String newName) {
    name = newName;
    notifyListeners();
  }

  void updateMode(LabelingMode newMode) {
    mode = newMode;
    notifyListeners();
  }

  void updateClasses(List<String> newClasses) {
    classes = newClasses;
    notifyListeners();
  }

  void updateDataInfos(List<DataInfo> newDataInfos) {
    dataInfos = newDataInfos;
    notifyListeners();
  }

  void addDataInfo(DataInfo newDataInfo) {
    dataInfos = [...dataInfos, newDataInfo];
    notifyListeners();
  }

  void removeDataInfoById(String dataId) {
    dataInfos = dataInfos.where((d) => d.id != dataId).toList();
    notifyListeners();
  }

  void resetLabels() {
    labels = [];
    notifyListeners();
  }

  void clearLabels() {
    labels.clear();
    notifyListeners();
  }

  /// ✅ JSON 데이터를 기반으로 `Project` 객체 생성
  factory Project.fromJson(Map<String, dynamic> json) {
    final modeStr = json['mode'];
    late final LabelingMode mode;

    try {
      mode = LabelingMode.values.byName(modeStr);
    } catch (_) {
      debugPrint("⚠️ Invalid labeling mode: $modeStr → fallback to singleClassification");
      mode = LabelingMode.singleClassification;
    }

    return Project(
      id: json['id'],
      name: json['name'],
      mode: mode,
      classes: List<String>.from(json['classes']),
      dataInfos: (json['dataInfos'] as List?)?.map((e) => DataInfo.fromJson(e)).toList() ?? [],
      labels: (json['label'] as List?)?.map((e) => LabelModelConverter.fromJson(mode, e)).toList() ?? [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// ✅ `Project` 객체를 JSON 형식으로 변환
  Map<String, dynamic> toJson({bool includeLabels = true}) {
    final map = {'id': id, 'name': name, 'mode': mode.name, 'classes': classes, 'dataInfos': dataInfos.map((e) => e.toJson()).toList()};

    if (includeLabels) {
      map['label'] = labels.map((e) => LabelModelConverter.toJson(e)).toList();
    }

    return map;
  }
}
