// lib/src/platform_helpers/storage/web_storage_helper.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:archive/archive.dart';

import 'interface_storage_helper.dart'; // ← 현재는 여기에 LabelModelConverter가 있다고 가정
import '../../core/models/project/project_model.dart';
import '../../core/models/data/data_info.dart';
import '../../core/models/label/label_model.dart';
// 필요 시 LabelModelFactory가 다른 파일이면 import 경로를 맞춰주세요.

/// Web(브라우저) 환경용 StorageHelper 구현.
/// - 원본 데이터는 브라우저 private storage(예: IndexedDB/메모리)에 상주한다고 가정.
/// - 스토리지 헬퍼는 원본 파일을 별도 저장하지 않고, Export 시에만 base64 → bytes로 ZIP에 포함.
/// - 라벨 직렬화는 표준 래퍼 스키마를 사용:
///   {
///     "data_id": "<데이터 ID>",
///     "data_path": "<파일명/경로|null>",
///     "labeled_at": "YYYY-MM-DDTHH:mm:ss.sssZ",
///     "mode": "<LabelingMode.name>",
///     "label_data": { ... } // LabelModel.toJson()
///   }
class StorageHelperImpl implements StorageHelperInterface {
  // ==============================
  // 📌 Keys & Utils
  // ==============================

  static const _kPrefix = 'zae_labeler:';
  static const _kProjectConfigKey = '${_kPrefix}project_config_snapshots';
  static const _kProjectListKey = '${_kPrefix}project_registry';

  String _labelsKey(String projectId) => '${_kPrefix}labels:$projectId';

  String _stripDataUrl(String s) {
    final i = s.indexOf(',');
    return s.startsWith('data:') && i != -1 ? s.substring(i + 1) : s;
  }

  // ==============================
  // 📌 Project Configuration IO
  // ==============================

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    // 설계도 스냅샷: 라벨/대용량 제외 권장
    final list = projects.map((p) {
      final j = p.toJson(includeLabels: false);
      // DataInfo는 최소 필드만 유지(웹에선 path/base64 저장 불필요)
      j['dataInfos'] = (j['dataInfos'] as List).map((e) {
        final m = (e as Map).cast<String, dynamic>();
        return {'id': m['id'], 'fileName': m['fileName']};
      }).toList();
      return j;
    }).toList();
    html.window.localStorage[_kProjectConfigKey] = jsonEncode(list);
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
    // 인자로 받은 문자열(JSON)을 파싱하여 복원
    try {
      final data = jsonDecode(projectConfig);
      final list = (data as List).cast<Map<String, dynamic>>();
      return list.map(Project.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    // 라벨 제외 + DataInfo 슬림화
    final j = project.toJson(includeLabels: false);
    j['dataInfos'] = (j['dataInfos'] as List).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return {'id': m['id'], 'fileName': m['fileName']};
    }).toList();

    final jsonString = jsonEncode(j);
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_config.json")
      ..click();
    html.Url.revokeObjectUrl(url);
    return "${project.name}_config.json";
  }

  // ==============================
  // 📌 Project List Management
  // ==============================

  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final projectsJson = jsonEncode(projects.map((e) => e.toJson(includeLabels: false)).toList());
    html.window.localStorage[_kProjectListKey] = projectsJson;
  }

  @override
  Future<List<Project>> loadProjectList() async {
    final projectsJson = html.window.localStorage[_kProjectListKey];
    if (projectsJson == null) return [];
    final jsonData = jsonDecode(projectsJson);
    return (jsonData as List).map((e) => Project.fromJson(e)).toList();
  }

  // ==============================
  // 📌 Single Label Data IO
  // ==============================

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    final storageKey = _labelsKey(projectId);
    final labelsJson = html.window.localStorage[storageKey];

    List<Map<String, dynamic>> entries = [];
    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson) as List;
      entries = jsonData.cast<Map<String, dynamic>>();
    }

    final entry = <String, dynamic>{
      'data_id': dataId,
      'data_path': dataPath,
      'mode': labelModel.mode.name, // enum.name
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'label_data': LabelModelConverter.toJson(labelModel),
    };

    final idx = entries.indexWhere((e) => e['data_id'] == dataId);
    if (idx >= 0) {
      entries[idx] = entry;
    } else {
      entries.add(entry);
    }

    html.window.localStorage[storageKey] = jsonEncode(entries);
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode modeHint) async {
    final storageKey = _labelsKey(projectId);
    final labelsJson = html.window.localStorage[storageKey];
    if (labelsJson == null) {
      return LabelModelFactory.createNew(modeHint, dataId: dataId);
    }

    final entries = (jsonDecode(labelsJson) as List).cast<Map<String, dynamic>>();
    final entry = entries.firstWhere((e) => e['data_id'] == dataId, orElse: () => const {});

    if (entry.isEmpty) {
      return LabelModelFactory.createNew(modeHint, dataId: dataId);
    }

    final modeName = entry['mode'] as String?;
    final mode = modeName != null ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => modeHint) : modeHint;

    // ✅ converter에 래퍼 전체(Map) 전달
    return LabelModelConverter.fromJson(mode, entry);
  }

  // ==============================
  // 📌 Project-wide Label IO
  // ==============================

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final storageKey = _labelsKey(projectId);

    final entries = labels
        .map((m) => <String, dynamic>{
              'data_id': m.dataId,
              'data_path': m.dataPath,
              'labeled_at': m.labeledAt.toIso8601String(),
              'mode': m.mode.name, // enum.name
              'label_data': LabelModelConverter.toJson(m),
            })
        .toList();

    html.window.localStorage[storageKey] = jsonEncode(entries);
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    final storageKey = _labelsKey(projectId);
    final labelsJson = html.window.localStorage[storageKey];
    if (labelsJson == null) return const [];

    final entries = (jsonDecode(labelsJson) as List).cast<Map<String, dynamic>>();
    return [
      for (final e in entries)
        LabelModelConverter.fromJson(
          (e['mode'] is String)
              ? LabelingMode.values.firstWhere((m) => m.name == e['mode'], orElse: () => LabelingMode.singleClassification)
              : LabelingMode.singleClassification,
          e, // ✅ 래퍼 전체 전달
        )
    ];
  }

  @override
  Future<void> deleteProjectLabels(String projectId) async {
    final storageKey = _labelsKey(projectId);
    html.window.localStorage.remove(storageKey);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await deleteProjectLabels(projectId);
    // 필요 시 _kProjectListKey에서 해당 project를 제거하는 로직 추가 가능
  }

  // ==============================
  // 📌 Label Data Import/Export
  // ==============================

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labels, List<DataInfo> fileDataList) async {
    final archive = Archive();

    // 1) 원본 파일(base64 → bytes)
    for (final info in fileDataList) {
      if (info.base64Content == null || info.base64Content!.isEmpty) continue;
      final bytes = base64Decode(_stripDataUrl(info.base64Content!));
      archive.addFile(ArchiveFile(info.fileName, bytes.length, bytes));
    }

    // 2) labels.json (표준 래퍼) — 혼합 모드 가능성 방어를 위해 각 라벨의 mode 사용
    final entries = labels
        .map((m) => <String, dynamic>{
              'data_id': m.dataId,
              'data_path': m.dataPath,
              'labeled_at': m.labeledAt.toIso8601String(),
              'mode': m.mode.name,
              'label_data': LabelModelConverter.toJson(m),
            })
        .toList();
    final text = jsonEncode(entries);
    archive.addFile(ArchiveFile('labels.json', text.length, utf8.encode(text)));

    // 3) ZIP → 브라우저 다운로드 트리거
    final zip = ZipEncoder().encode(archive)!;
    final blob = html.Blob([zip]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', '${project.name}_labels.zip')
      ..click();
    html.Url.revokeObjectUrl(url);
    return '${project.name}_labels.zip';
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    final input = html.FileUploadInputElement()..accept = '.json,application/json';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return const [];

    final file = input.files!.first;
    final reader = html.FileReader()..readAsText(file);
    await reader.onLoadEnd.first;

    final text = reader.result as String;
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();

    final models = <LabelModel>[];
    for (final e in list) {
      final modeName = e['mode'] as String?;
      final mode = modeName != null
          ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => LabelingMode.singleClassification)
          : LabelingMode.singleClassification;
      // ✅ 래퍼 전체 전달
      models.add(LabelModelConverter.fromJson(mode, e));
    }
    return models;
  }

  // ==============================
  // 📌 Cache Management
  // ==============================

  @override
  Future<void> clearAllCache() async {
    // 앱 prefix만 정리 (브라우저 전체 localStorage를 지우지 않음)
    final keysToRemove = <String>[];
    for (var i = 0; i < html.window.localStorage.length; i++) {
      final k = html.window.localStorage.keys.elementAt(i);
      if (k.startsWith(_kPrefix)) keysToRemove.add(k);
    }
    for (final k in keysToRemove) {
      html.window.localStorage.remove(k);
    }
  }
}
