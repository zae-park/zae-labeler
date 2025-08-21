// lib/src/core/models/label/base_label_model.dart

/*
이 파일은 라벨링 모델의 공통 계약(추상 클래스)을 정의합니다.
개별 라벨 서브모델(분류/세그멘테이션 등)은 이 클래스를 상속하여
필수 속성/행동을 구현합니다.

직렬화 규약:
- 각 서브모델의 `toJson()`은 "내부(label_data)" 전용 JSON을 반환합니다.
- 외부 래퍼( data_id, data_path, labeled_at, mode, label_data )는
  LabelModelConverter가 생성/파싱합니다.
*/

import 'label_types.dart'; // LabelingMode 등 공용 정의

/// ✅ LabelModel의 최상위 추상 클래스 (Base Model)
///
/// # 역할
/// - 모든 라벨 서브모델이 공통으로 가져야 하는 필드/계약을 정의합니다.
/// - JSON 직렬화는 "내부(label_data)"만 책임지며, 래퍼는 Converter에서 처리합니다.
///
/// # 필드 설명
/// - [dataId] : 프로젝트의 `DataInfo.id`와 1:1로 매칭되는 식별자(조인 키)
/// - [dataPath] : (선택) 네이티브에서만 사용하는 실제 파일 경로
///                웹/클라우드에서는 보통 `null`
/// - [label] : 실제 라벨 페이로드(모드별 타입 다름)
/// - [labeledAt] : 이 라벨이 마지막으로 저장(갱신)된 시간
///
/// # 계약(서브클래스가 구현)
/// - [isMultiClass] : 다중 클래스(멀티 라벨)인지 여부
/// - [isLabeled] : “라벨이 유효하게 채워졌는지” 판단(모드별 기준 상이)
/// - [mode] : 모델이 표현하는 라벨링 모드
/// - [toJson] :
/// - [toPayloadJson] : "내부(label_data) JSON"만 반환
/// - [fromJson] :
/// - [fromPayloadJson] :
abstract class LabelModel<T> {
  /// 프로젝트 데이터와 매칭되는 식별자(조인 키).
  /// 저장/조회 시 이 값으로 해당 데이터의 라벨을 찾습니다.
  final String dataId;

  /// (옵션) 로컬/네이티브 환경에서의 실제 파일 경로.
  /// 웹/클라우드에서는 보통 null이며, 경로 의존 로직은 피하세요.
  final String? dataPath;

  /// 실제 라벨 페이로드. 모드별 타입이 달라집니다.
  /// - Single/Multi Classification: `String` 또는 `Set<String>`
  /// - Cross Classification: `CrossDataPair`
  /// - Segmentation: `SegmentationData`
  final T? label;

  /// 최종 저장(갱신) 시각. UI 표기/정렬 등에 사용할 수 있습니다.
  final DateTime labeledAt;

  LabelModel({required this.dataId, this.dataPath, required this.label, required this.labeledAt});

  /// 이 라벨이 “멀티 클래스(다중 선택)” 성격인지 여부.
  /// UI 토글/선택 로직에서 사용됩니다.
  bool get isMultiClass;

  /// 라벨 페이로드 접근용 별칭.
  /// (읽기 전용, 동의어 형태로 제공)
  T? get labelData => label;

  /// ISO-8601 문자열로 포맷된 최종 저장 시각.
  /// 디버그/로그 출력 등에서 편하게 사용하세요.
  String get formattedLabeledAt => labeledAt.toIso8601String();

  /// 이 라벨이 “유효하게 채워졌는지” 여부.
  /// 모드별 기준이 다르므로 서브모델에서 정의하세요.
  bool get isLabeled;

  /// 이 모델이 표현하는 라벨링 모드.
  /// (예: singleClassification / multiClassification / segmentation ...)
  LabelingMode get mode;

  /// ✍️ 내부(label_data) 전용 JSON 직렬화.
  /// - 외부 래퍼( data_id, data_path, labeled_at, mode )는 포함하지 않습니다.
  /// - 래퍼 생성/파싱은 LabelModelConverter가 담당합니다.
  Map<String, dynamic> toPayloadJson();
}
