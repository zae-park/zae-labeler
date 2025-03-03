// lib/src/models/project_model.dart
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
  String id; // 프로젝트 고유 ID
  String name; // 프로젝트 이름

  List<String> classes; // 설정된 클래스 목록
  List<DataPath> dataPaths; // Web과 Native 모두 지원하는 데이터 경로
  List<LabelModel> labels; // ✅ 라벨 데이터 관리 (LabelEntry → LabelModel 변경)

  final LabelingMode mode; // 라벨링 모드

  Project({
    required this.id,
    required this.name,
    required this.mode,
    required this.classes,
    this.dataPaths = const [],
    this.labels = const [], // ✅ 라벨 데이터를 `LabelModel` 기반으로 관리
  });

  /// ✅ JSON 데이터를 기반으로 `Project` 객체 생성
  factory Project.fromJson(Map<String, dynamic> json) {
    final mode = LabelingMode.values.firstWhere((e) => e.toString().split('.').last == json['mode']);
    return Project(
      id: json['id'],
      name: json['name'],
      mode: mode,
      classes: List<String>.from(json['classes']),
      dataPaths: (json['dataPaths'] as List).map((e) => DataPath.fromJson(e)).toList(),
      labels: (json['labels'] as List?)?.map((e) => LabelModelConverter.fromJson(mode, e)).toList() ?? [],
    );
  }

  /// ✅ `Project` 객체를 JSON 형식으로 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.toString().split('.').last,
        'classes': classes,
        'dataPaths': dataPaths.map((e) => e.toJson()).toList(),
        'labels': labels.map((e) => LabelModelConverter.toJson(e)).toList(),
      };

  /// ✅ StorageHelper를 사용하여 모든 라벨 데이터 로드
  Future<void> loadAllLabels() async {
    labels = await StorageHelper.instance.loadAllLabels(id);
  }

  /// ✅ 특정 데이터에 대한 라벨을 불러옴
  Future<LabelModel> loadLabel(String dataPath) async {
    return await StorageHelper.instance.loadLabelData(id, dataPath, mode);
  }

  /// ✅ 특정 데이터의 라벨을 저장
  Future<void> saveLabel(String dataPath, LabelModel labelModel) async {
    await StorageHelper.instance.saveLabelData(id, dataPath, labelModel);
  }

  /// ✅ 프로젝트의 모든 라벨을 저장
  Future<void> saveAllLabels() async {
    await StorageHelper.instance.saveAllLabels(id, labels);
  }
}
