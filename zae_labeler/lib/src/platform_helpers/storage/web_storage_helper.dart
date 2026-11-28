// lib/src/platform_helpers/storage/web_storage_helper.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:archive/archive.dart';

import 'interface_storage_helper.dart'; // ← 현재는 여기에 LabelModelConverter가 있다고 가정
import '../../core/models/project/project_model.dart';
import '../../core/models/data/data_info.dart';
import '../../core/models/label/label_model.dart';

/// Web(브라우저) 환경용 StorageHelper 구현.
///
/// - 옵션 A(현 적용): 프로젝트 저장/다운로드/레지스트리 저장 시
///   DataInfo를 `{id,fileName,filePath,mimeType}`만 남기는 슬림화로 직렬화한다.
///   즉, base64/objectUrl 같은 휘발 값은 저장 시 제거되며, 재로딩 가능성을 위해
///   http(s) `filePath`와 `mimeType`은 반드시 보존한다.
///
/// - 옵션 B(문서화): 프로젝트 도큐먼트를 최소화하고,
///   `users/{uid}/projects/{projectId}/metadata/dataIndex` 같은 별도 문서에
///   `{ data_id: {filePath, mimeType} }` 형태로 저장한 뒤,
///   로드 시 해당 맵을 읽어 `DataInfo.copyWith(filePath, mimeType)`로 합성하는 전략도 가능.
///   대규모 프로젝트에서 문서 크기를 더 줄이고 확장 메타를 점진적으로 늘리기 좋다.
class StorageHelperImpl implements StorageHelperInterface {
  // Blob URL 해제 관리를 위한 내부 캐시
  final Set<String> _blobUrls = <String>{};

  // ==============================
  // 📌 Keys & Utils
  // ==============================

  static const _kPrefix = 'zae_labeler:';
  static const _kProjectConfigKey = '${_kPrefix}project_config_snapshots';
  static const _kProjectListKey = '${_kPrefix}project_registry';

  String _labelsKey(String projectId) => '${_kPrefix}labels:$projectId';

  // ==============================
  // 📌 Project Configuration IO
  // ==============================

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    // 설계도 스냅샷: 라벨/대용량 제외 권장
    final list = projects.map((p) {
      final j = p.toJson(includeLabels: false);
      // ✅ 옵션 A: 재로딩 가능성을 위해 DataInfo 슬림화({id,fileName,filePath,mimeType}) 적용
      j['dataInfos'] = (j['dataInfos'] as List).map((e) => DataInfo.fromJson((e as Map).cast<String, dynamic>()).toSlimJson()).toList();
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
    j['dataInfos'] = (j['dataInfos'] as List).map((e) => DataInfo.fromJson((e as Map).cast<String, dynamic>()).toSlimJson()).toList();

    final jsonString = jsonEncode(j);
    final blob = html.Blob([jsonString], 'application/json');
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
    // ✅ 옵션 A: 레지스트리에도 슬림화된 DataInfo만 저장
    final list = projects.map((p) {
      final j = p.toJson(includeLabels: false);
      j['dataInfos'] = (j['dataInfos'] as List).map((e) => DataInfo.fromJson((e as Map).cast<String, dynamic>()).toSlimJson()).toList();
      return j;
    }).toList();
    final projectsJson = jsonEncode(list);
    html.window.localStorage[_kProjectListKey] = projectsJson;
  }

  /// 로컬 레지스트리는 목록 하나로 저장되므로, 해당 항목만 교체해 다시 씁니다.
  @override
  Future<void> saveProject(Project project) async {
    final list = await loadProjectList();
    final i = list.indexWhere((p) => p.id == project.id);
    i < 0 ? list.add(project) : list[i] = project;
    await saveProjectList(list);
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
        .map(
          (m) => <String, dynamic>{
            'data_id': m.dataId,
            'data_path': m.dataPath,
            'labeled_at': m.labeledAt.toIso8601String(),
            'mode': m.mode.name, // enum.name
            'label_data': LabelModelConverter.toJson(m),
          },
        )
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
        ),
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

    // 1) 원본 파일: base64 우선, 없으면 http(s)로 fetch하여 포함 (CORS/인증 실패 시 생략)
    for (final info in fileDataList) {
      Uint8List? bytes;
      final b64 = info.base64Content?.trim();
      if (b64 != null && b64.isNotEmpty) {
        final raw = b64.contains(',') ? b64.split(',').last : b64;
        bytes = Uint8List.fromList(base64Decode(raw));
      } else if (info.filePath != null && info.filePath!.startsWith('http')) {
        try {
          final resp = await http.get(Uri.parse(info.filePath!));
          if (resp.statusCode == 200) bytes = resp.bodyBytes;
        } catch (_) {
          // CORS/인증 등으로 실패하면 포함하지 않음
        }
      }
      if (bytes != null) archive.addFile(ArchiveFile(info.fileName, bytes.length, bytes));
    }

    // 2) labels.json (표준 래퍼)
    final entries = labels
        .map(
          (m) => <String, dynamic>{
            'data_id': m.dataId,
            'data_path': m.dataPath,
            'labeled_at': m.labeledAt.toIso8601String(),
            'mode': m.mode.name,
            'label_data': LabelModelConverter.toJson(m),
          },
        )
        .toList();
    final text = jsonEncode(entries);
    archive.addFile(ArchiveFile('labels.json', text.length, utf8.encode(text)));

    // 3) ZIP → 브라우저 다운로드 트리거
    final zip = ZipEncoder().encode(archive);
    final blob = html.Blob([zip], 'application/zip');
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
  // 📌 Data Read
  // ==============================

  /// Web: base64Content 우선 → http(s) URL(옵션) → 그 외는 미지원
  @override
  Future<Uint8List> readDataBytes(DataInfo info) async {
    final b64 = info.base64Content?.trim();
    if (b64 != null && b64.isNotEmpty) {
      // data:<mime>;base64,XXXXX 형태와 순수 base64 모두 허용
      final raw = b64.contains(',') ? b64.split(',').last : b64;
      return Uint8List.fromList(base64Decode(raw));
    }

    final path = info.filePath?.trim();
    if (path != null && path.startsWith('http')) {
      final resp = await http.get(Uri.parse(path));
      if (resp.statusCode == 200) return resp.bodyBytes;
      throw StateError('HTTP ${resp.statusCode} while fetching $path');
    }

    throw UnsupportedError('Web cannot read local OS paths. Provide base64Content or an http(s) URL in DataInfo.');
  }

  /// Web: 바이트 → Blob → Object URL. 이미 objectUrl이 있으면 그대로 사용.
  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) async {
    if (info.objectUrl != null && info.objectUrl!.isNotEmpty) {
      return info.objectUrl;
    }
    final bytes = await readDataBytes(info);
    final blob = html.Blob(<dynamic>[bytes], info.mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    _blobUrls.add(url);
    return url;
  }

  /// Web: Blob URL 해제
  @override
  Future<void> revokeLocalObjectUrl(String url) async {
    if (_blobUrls.remove(url)) {
      html.Url.revokeObjectUrl(url);
    }
  }

  // ==============================
  // 📌 Cache Management
  // ==============================

  @override
  Future<void> clearAllCache() async {
    for (final url in _blobUrls) {
      html.Url.revokeObjectUrl(url);
    }
    _blobUrls.clear();
  }

  // ==============================
  // 📌 Object Upload (Cloud 우선)
  // ==============================
  @override
  Future<String> uploadText(String objectKey, String text, {String? contentType}) =>
      Future.error(UnsupportedError('uploadText is not supported in Web local storage'));

  @override
  Future<String> uploadBase64(String objectKey, String rawBase64, {String? contentType}) =>
      Future.error(UnsupportedError('uploadBase64 is not supported in Web local storage'));

  @override
  Future<String> uploadBytes(String objectKey, Uint8List bytes, {String? contentType}) =>
      Future.error(UnsupportedError('uploadBytes is not supported in Web local storage'));

  // ==============================
  // 📌 Project Upload (Cloud 우선)
  // ==============================
  @override
  Future<String> uploadProjectText(String projectId, String objectKey, String text, {String? contentType}) async =>
      UnsupportedError('Project-scoped upload is not supported in Native environment.').toString();

  @override
  Future<String> uploadProjectBase64(String projectId, String objectKey, String rawBase64, {String? contentType}) async =>
      UnsupportedError('Project-scoped upload is not supported in Native environment.').toString();

  /// 프로젝트 하위로 바이트 업로드
  @override
  Future<String> uploadProjectBytes(String projectId, String objectKey, Uint8List bytes, {String? contentType}) async =>
      UnsupportedError('Project-scoped upload is not supported in Native environment.').toString();
}
