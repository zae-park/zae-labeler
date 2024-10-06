// lib/src/models/label_model.dart
class Label {
  String dataId; // 데이터 고유 ID
  List<String> labels; // 할당된 라벨 목록

  Label({
    required this.dataId,
    required this.labels,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() => {
        'dataId': dataId,
        'labels': labels,
      };

  // JSON에서 객체 생성
  factory Label.fromJson(Map<String, dynamic> json) => Label(
        dataId: json['dataId'],
        labels: List<String>.from(json['labels']),
      );
}
