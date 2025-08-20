// lib/src/features/label/models/label_model_converter.dart
import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/models/label/label_types.dart';
import 'base_label_model.dart';
import 'classification_label_model.dart';
import 'segmentation_label_model.dart';

class LabelModelConverter {
  // ---- Public API ----------------------------------------------------------

  static Map<String, dynamic> toJson(LabelModel model) => model.toJson();

  static LabelModel fromJson(LabelingMode mode, Map<String, dynamic> raw) {
    final j = _normalize(raw); // 1) 표준화
    _validateWrapper(j); // 2) 공통 래퍼 최소 검증

    // (선택) 래퍼의 mode가 있다면 일치 확인
    final wrappedMode = j['mode'] as String?;
    if (wrappedMode != null && wrappedMode != mode.name) {
      debugPrint("[LabelModelConverter] ⚠️ mode mismatch: $wrappedMode != ${mode.name}");
    }

    switch (mode) {
      case LabelingMode.singleClassification:
        return _singleClassification(j);
      case LabelingMode.multiClassification:
        return _multiClassification(j);
      case LabelingMode.crossClassification:
        return _crossClassification(j);
      case LabelingMode.singleClassSegmentation:
        return _singleSeg(j);
      case LabelingMode.multiClassSegmentation:
        return _multiSeg(j);
    }
  }

  // ---- Strict parsers (표준 스키마만 신뢰) -----------------------------------

  static LabelModel _singleClassification(Map<String, dynamic> j) {
    final dataId = _reqString(j, 'data_id');
    final dataPath = _optString(j, 'data_path');
    final labeledAt = _readIsoDate(j, 'labeled_at');

    final payload = _reqMap(j, 'label_data');
    final label = _reqString(payload, 'label');

    return SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: label, labeledAt: labeledAt);
  }

  static LabelModel _multiClassification(Map<String, dynamic> j) {
    final dataId = _reqString(j, 'data_id');
    final dataPath = _optString(j, 'data_path');
    final labeledAt = _readIsoDate(j, 'labeled_at');

    final payload = _reqMap(j, 'label_data');
    final labels = _reqStringList(payload, 'labels');

    return MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: labels.toSet(), labeledAt: labeledAt);
  }

  static LabelModel _crossClassification(Map<String, dynamic> j) {
    final dataId = _reqString(j, 'data_id');
    final dataPath = _optString(j, 'data_path');
    final labeledAt = _readIsoDate(j, 'labeled_at');
    final payload = _reqMap(j, 'label_data'); // CrossDataPair JSON 전체

    return CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: CrossDataPair.fromJson(payload), labeledAt: labeledAt);
  }

  static LabelModel _singleSeg(Map<String, dynamic> j) {
    final dataId = _reqString(j, 'data_id');
    final dataPath = _optString(j, 'data_path');
    final labeledAt = _readIsoDate(j, 'labeled_at');
    final payload = _reqMap(j, 'label_data');

    return SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: SegmentationData.fromJson(payload), labeledAt: labeledAt);
  }

  static LabelModel _multiSeg(Map<String, dynamic> j) {
    final dataId = _reqString(j, 'data_id');
    final dataPath = _optString(j, 'data_path');
    final labeledAt = _readIsoDate(j, 'labeled_at');
    final payload = _reqMap(j, 'label_data');

    return MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: SegmentationData.fromJson(payload), labeledAt: labeledAt);
  }

  // ---- Normalize: 레거시 입력을 표준 스키마로 변환 --------------------------

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
    } else if (raw['label'] is String) {
      normalized['label_data'] = {'label': raw['label']};
    } else if (raw['labels'] is List) {
      normalized['label_data'] = {'labels': List<String>.from((raw['labels'] as List).map((e) => e.toString()))};
    } else if (raw['label'] is Map) {
      // segmentation 등: 기존에 label 키 안에 오브젝트가 있었던 경우
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

  // ---- tiny readers (타입 안전 리더) ---------------------------------------

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

  static List<String> _reqStringList(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    throw FormatException("Missing array '$key'");
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
