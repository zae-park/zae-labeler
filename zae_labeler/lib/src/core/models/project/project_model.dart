// lib/src/models/project_model.dart  (또는 이동: lib/src/core/models/project/project_model.dart)
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:zae_labeler/src/platform_helpers/storage/get_storage_helper.dart';

import '../data/data_model.dart';
// ✅ label_model은 아직 core로 안 옮겼으므로 기존 경로 그대로 유지
import '../../../features/label/models/label_model.dart';

/// 프로젝트 도메인 엔티티(순수 객체).
/// - 저장소/뷰모델/페이지에 의존하지 않음 (ChangeNotifier 제거)
/// - 모든 필드는 불변(final), 상태 변경은 copyWith로만 수행
/// - JSON 직렬화/역직렬화만 담당
class Project {
  final String id; // 프로젝트 고유 ID
  final String name; // 프로젝트 이름
  final LabelingMode mode; // 라벨링 모드 (label_model에서 제공)
  final List<String> classes; // 프로젝트에서 사용하는 클래스 목록
  final List<DataInfo> dataInfos; // 데이터 경로/메타 정보 (웹/네이티브 공용 구조)
  final List<LabelModel> labels; // 라벨 데이터 (보관만 함. 가공/검증/변환은 UseCase/VM에서)

  const Project({required this.id, required this.name, required this.mode, required this.classes, this.dataInfos = const [], this.labels = const []});

  /// 테스트/초기화용 빈 프로젝트
  factory Project.empty() => const Project(id: 'empty', name: '', mode: LabelingMode.singleClassification, classes: <String>[]);

  /// 불변 객체 갱신 (얕은 복사)
  Project copyWith({String? id, String? name, LabelingMode? mode, List<String>? classes, List<DataInfo>? dataInfos, List<LabelModel>? labels}) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      classes: classes ?? List<String>.unmodifiable(this.classes),
      dataInfos: dataInfos ?? List<DataInfo>.unmodifiable(this.dataInfos),
      labels: labels ?? List<LabelModel>.unmodifiable(this.labels),
    );
  }

  /// JSON → Project (라벨 키: 'label' | 'labels' 모두 허용)
  factory Project.fromJson(Map<String, dynamic> json) {
    final modeStr = json['mode'];
    late final LabelingMode resolvedMode;

    try {
      resolvedMode = LabelingMode.values.byName(modeStr);
    } catch (_) {
      debugPrint("⚠️ Invalid labeling mode: $modeStr → fallback to singleClassification");
      resolvedMode = LabelingMode.singleClassification;
    }

    // labels: 'label' or 'labels' 키 허용
    final dynamic labelsRaw = json['label'] ?? json['labels'];

    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: resolvedMode,
      classes: List<String>.from(json['classes'] ?? const []),
      dataInfos: (json['dataInfos'] as List?)?.map((e) => DataInfo.fromJson(e as Map<String, dynamic>)).toList().cast<DataInfo>() ?? const <DataInfo>[],
      labels: (labelsRaw as List?)?.map((e) => LabelModelConverter.fromJson(resolvedMode, e)).toList().cast<LabelModel>() ?? const <LabelModel>[],
    );
  }

  /// Project → JSON
  /// - includeLabels=false면 라벨은 제외 (목록 전송/목록 캐시 등에 유용)
  Map<String, dynamic> toJson({bool includeLabels = true}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'mode': mode.name,
      'classes': classes,
      'dataInfos': dataInfos.map((e) => e.toJson()).toList(),
    };

    if (includeLabels) {
      map['label'] = labels.map((e) => LabelModelConverter.toJson(e)).toList();
    }
    return map;
  }

  String toJsonString({bool includeLabels = true}) => jsonEncode(toJson(includeLabels: includeLabels));
}
