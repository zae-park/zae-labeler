// lib/src/core/models/label/label_model_converter.dart
import 'package:flutter/foundation.dart';

import 'label_types.dart';
import 'base_label_model.dart';
import 'classification_label_model.dart';
import 'segmentation_label_model.dart';

/// ✅ LabelModelConverter
/// - 모델 ↔ JSON 변환을 담당 (레거시 입력도 안전하게 수용)
/// - 표준 래퍼 스키마:
///   {
///     "data_id": "...",
///     "data_path": "...",          // opt
///     "labeled_at": "ISO-8601",
///     "mode": "singleClassification" | ...,
///     "label_data": { ... }        // 모델별 페이로드
///   }
class LabelModelConverter {
  /// 모델 → (모델 고유 페이로드) JSON
  /// - 주의: 래퍼를 포함하지 않습니다. (스토리지에서 래퍼를 씌우세요)
  static Map<String, dynamic> toJson(LabelModel model) => model.toPayloadJson();

  /// JSON → 모델
  /// - `raw`는 표준 래퍼 혹은 레거시 페이로드 모두 허용
  /// - 내부에서 정규화 후, 최소 검증을 거쳐 안전 파싱
  static LabelModel fromJson(LabelingMode mode, Map<String, dynamic> raw) {
    final j = _normalize(raw); // 1) 표준화
    _validateWrapper(j); // 2) 공통 래퍼 최소 검증

    // (선택) 래퍼의 mode가 있다면 일치 확인
    final wrappedMode = j['mode'] as String?;
    if (wrappedMode != null && wrappedMode != mode.name) {
      debugPrint("[LabelModelConverter] ⚠️ mode mismatch: $wrappedMode != ${mode.name}");
    }

    final dataId = _reqString(j, 'data_id');
    final dataPath = _optString(j, 'data_path');
    final labeledAt = _readIsoDate(j, 'labeled_at');
    final payload = _reqMap(j, 'label_data');

    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel.fromPayloadJson(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt, payload: payload);

      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel.fromPayloadJson(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt, payload: payload);

      case LabelingMode.crossClassification:
        return CrossClassificationLabelModel.fromPayloadJson(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt, payload: payload);

      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabelModel.fromPayloadJson(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt, payload: payload);

      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabelModel.fromPayloadJson(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt, payload: payload);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Normalize: 레거시 입력을 표준 스키마로 변환
  // ───────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    // 1) 키 표준화
    final normalized = <String, dynamic>{
      'data_id': raw['data_id'] ?? raw['dataId'],
      'data_path': raw['data_path'] ?? raw['dataPath'],
      'labeled_at': raw['labeled_at'] ?? raw['labeledAt'],
      'mode': raw['mode'], // 있으면 검증용
    };

    // 2) payload 정규화
    if (raw['label_data'] is Map) {
      normalized['label_data'] = Map<String, dynamic>.from(raw['label_data'] as Map);
    } else if (raw['labels'] is List) {
      // 다중 분류 레거시: labels가 배열
      normalized['label_data'] = {
        'labels': List<String>.from((raw['labels'] as List).map((e) => e.toString())),
      };
    } else if (raw['label'] is String) {
      // 단일 분류 레거시: label이 문자열
      normalized['label_data'] = {'label': raw['label']};
    } else if (raw['label'] is List) {
      // 일부 레거시 구현에서 multi를 label(List)로 저장했을 수 있음 → 표준화
      normalized['label_data'] = {
        'labels': List<String>.from((raw['label'] as List).map((e) => e.toString())),
      };
    } else if (raw['label'] is Map) {
      // 세그멘테이션/크로스 라벨: label 키 안에 오브젝트가 있었던 경우
      normalized['label_data'] = Map<String, dynamic>.from(raw['label'] as Map);
    } else {
      normalized['label_data'] = <String, dynamic>{};
    }

    return normalized;
  }

  static void _validateWrapper(Map<String, dynamic> j) {
    if (j['data_id'] == null) {
      throw const FormatException("data_id is required");
    }
    if (j['label_data'] is! Map) {
      throw const FormatException("label_data must be an object");
    }
    // labeled_at은 _readIsoDate에서 폴백 처리
  }

  /// 모델 + 공통 메타를 표준 래퍼 스키마로 감싼 JSON을 만들어줍니다.
  /// 저장소(Firestore/Storage)에 기록할 때 이걸 그대로 쓰면 됩니다.
  static Map<String, dynamic> wrap(LabelModel model) {
    return {
      'data_id': model.dataId,
      'data_path': model.dataPath,
      'labeled_at': model.labeledAt.toIso8601String(),
      'mode': model.mode.name,
      'label_data': model.toPayloadJson(), // ← 모델이 보장하는 표준 페이로드
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // tiny readers (타입 안전 리더)
  // ───────────────────────────────────────────────────────────────────────────

  static String _reqString(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException("Missing/empty '$key'");
  }

  static String? _optString(Map<String, dynamic> j, String key) {
    final v = j[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  static Map<String, dynamic> _reqMap(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is Map) return Map<String, dynamic>.from(v);
    throw FormatException("Missing object '$key'");
  }

  static DateTime _readIsoDate(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is String) {
      final t = DateTime.tryParse(v);
      if (t != null) return t;
    }
    return DateTime.now();
  }
}
