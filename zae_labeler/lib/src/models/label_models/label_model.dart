/// ✅ LabelType의 최상위 클래스 (모든 Label의 기본 인터페이스)
abstract class LabelModel {
  String labeledAt; // 라벨이 부여된 시간 (ISO 8601 형식)

  LabelModel({required this.labeledAt});

  /// JSON 변환 메서드 (모든 Label 모델이 구현해야 함)
  Map<String, dynamic> toJson();
}
