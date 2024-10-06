// lib/src/models/project_model.dart
class Project {
  String id; // 프로젝트 고유 ID
  String name; // 프로젝트 이름
  LabelingMode mode; // 라벨링 모드
  List<String> classes; // 설정된 클래스 목록

  Project({
    required this.id,
    required this.name,
    required this.mode,
    required this.classes,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.toString(),
        'classes': classes,
      };

  // JSON에서 객체 생성
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        mode: LabelingMode.values.firstWhere(
            (e) => e.toString() == json['mode'],
            orElse: () => LabelingMode.singleClassification),
        classes: List<String>.from(json['classes']),
      );
}

// 라벨링 모드 열거형
enum LabelingMode {
  singleClassification,
  multiClassification,
  segmentation,
}
