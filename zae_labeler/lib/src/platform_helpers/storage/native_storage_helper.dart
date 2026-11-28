// lib/src/platform_helpers/storage/native_storage_helper.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'interface_storage_helper.dart'; // ← 현재는 여기에 LabelModelConverter가 있다고 가정
import '../../core/models/data/data_info.dart';
import '../../core/models/project/project_model.dart';
import '../../core/models/label/label_model.dart';
// 필요 시 LabelModelFactory 경로가 다르면 import 추가

/// Native(모바일/데스크톱) 환경용 StorageHelper 구현.
///
/// - 옵션 A(현 적용): 프로젝트 저장/다운로드/레지스트리 저장 시
///   DataInfo를 `{id,fileName,filePath,mimeType}`로 **슬림화**하여 직렬화한다.
///   (대용량/휘발 필드인 base64Content/objectUrl은 저장하지 않음)
///
/// - 옵션 B(문서화): 프로젝트 메타는 더 작게 유지하고,
///   `users/{uid}/projects/{projectId}/metadata/dataIndex` 같은 별도 저장소(클라우드/로컬)에
///   `{ data_id: {filePath, mimeType} }` 맵을 별도 기록한 뒤,
///   로드 시 해당 맵을 읽어 각 `DataInfo`에 `copyWith(filePath,mimeType)`로 **합성**한다.
///   대규모 프로젝트에서 확장 메타 관리가 쉬워진다.
///
/// - 원본 데이터는 로컬 파일시스템 경로(DataInfo.filePath)로 접근.
/// - 스토리지 헬퍼는 원본 파일을 이동/복사하지 않으며, Export 시에만 읽어 ZIP에 포함.
/// - 라벨 직렬화는 표준 래퍼 스키마를 사용.
class StorageHelperImpl implements StorageHelperInterface {
  // ─────────────────────────────────────────────────────────────────────────
  // Keys / Paths / Utils
  // ─────────────────────────────────────────────────────────────────────────

  static const _kConfigFileName = 'project_config_snapshots.json';
  static const _kRegistryFileName = 'project_registry.json';

  String _labelsFileName(String projectId) => 'labels_project_$projectId.json';

  Future<File> _docFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, name));
  }

  String _stripDataUrl(String s) {
    final i = s.indexOf(',');
    return s.startsWith('data:') && i != -1 ? s.substring(i + 1) : s;
  }

  Future<List<Map<String, dynamic>>> _readJsonList(File f) async {
    if (!await f.exists()) return <Map<String, dynamic>>[];
    final text = await f.readAsString();
    final data = jsonDecode(text);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return <Map<String, dynamic>>[];
  }

  Future<void> _writeJsonList(File f, List<Map<String, dynamic>> list) async {
    // 간단하고 안전한 쓰기 (필요시 tmp→rename 패턴으로 바꿀 수 있음)
    await f.writeAsString(jsonEncode(list), flush: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project Configuration IO (설계도 스냅샷; 라벨/대용량 제외)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    final file = await _docFile(_kConfigFileName);

    final list = projects.map((p) {
      final j = p.toJson(includeLabels: false);
      // ✅ 옵션 A: 재로딩 가능성을 위해 DataInfo 슬림화({id,fileName,filePath,mimeType}) 적용
      j['dataInfos'] = (j['dataInfos'] as List).map((e) => DataInfo.fromJson((e as Map).cast<String, dynamic>()).toSlimJson()).toList();
      return j;
    }).toList();

    await file.writeAsString(jsonEncode(list), flush: true);
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
    // 인자로 받은 JSON 문자열을 파싱하여 복원 (파일에서 읽지 않음)
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

    final file = await _docFile('${project.name}_config.json');
    await file.writeAsString(jsonEncode(j), flush: true);
    return file.path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project List Management (앱 내부 레지스트리/최근 목록)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final file = await _docFile(_kRegistryFileName);

    // ✅ 옵션 A: 레지스트리에도 슬림화된 DataInfo만 저장
    final list = projects.map((p) {
      final j = p.toJson(includeLabels: false);
      j['dataInfos'] = (j['dataInfos'] as List).map((e) => DataInfo.fromJson((e as Map).cast<String, dynamic>()).toSlimJson()).toList();
      return j;
    }).toList();

    await file.writeAsString(jsonEncode(list), flush: true);
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
    final file = await _docFile(_kRegistryFileName);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final jsonData = jsonDecode(content);
    return (jsonData as List).map((e) => Project.fromJson(e)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Single Label Data IO
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    final file = await _docFile(_labelsFileName(projectId));
    final entries = await _readJsonList(file);

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

    await _writeJsonList(file, entries);
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode modeHint) async {
    final file = await _docFile(_labelsFileName(projectId));
    if (!await file.exists()) {
      // 없으면 새 라벨 반환 (팩토리 사용 가능 시 교체)
      return LabelModelConverter.fromJson(modeHint, {'data_id': dataId});
    }

    final entries = await _readJsonList(file);
    final entry = entries.firstWhere((e) => e['data_id'] == dataId, orElse: () => const {});

    if (entry.isEmpty) {
      return LabelModelConverter.fromJson(modeHint, {'data_id': dataId});
    }

    // entry의 mode를 우선, 없으면 hint
    final modeName = entry['mode'] as String?;
    final mode = modeName != null ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => modeHint) : modeHint;

    // ✅ converter에 래퍼 전체(Map) 전달
    return LabelModelConverter.fromJson(mode, entry);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project-wide Label IO
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final file = await _docFile(_labelsFileName(projectId));

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

    await _writeJsonList(file, entries);
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    final file = await _docFile(_labelsFileName(projectId));
    if (!await file.exists()) return [];

    final entries = await _readJsonList(file);
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
    final file = await _docFile(_labelsFileName(projectId));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 프로젝트 단위 정리(라벨 파일 삭제 등).
  /// 필요 시 레지스트리에서 해당 프로젝트 제거 로직을 추가하세요.
  @override
  Future<void> deleteProject(String projectId) async {
    await deleteProjectLabels(projectId);
    // 레지스트리에서 프로젝트 제거가 필요하면 여기에 구현
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Label Data Import/Export
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labels, List<DataInfo> fileDataList) async {
    final archive = Archive();

    // 1) 원본 파일(바이너리) 추가
    for (final info in fileDataList) {
      List<int>? bytes;
      if (info.filePath != null) {
        final f = File(info.filePath!);
        if (await f.exists()) bytes = await f.readAsBytes();
      } else if (info.base64Content != null && info.base64Content!.isNotEmpty) {
        bytes = base64Decode(_stripDataUrl(info.base64Content!));
      }
      if (bytes != null) {
        archive.addFile(ArchiveFile(info.normalizedFileName, bytes.length, bytes));
      }
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

    final jsonText = jsonEncode(entries);
    archive.addFile(ArchiveFile('labels.json', jsonText.length, utf8.encode(jsonText)));

    // 3) zip 파일로 쓰기(임시 디렉터리)
    final outPath = p.join(Directory.systemTemp.path, '${project.name}_labels.zip');
    final zipData = ZipEncoder().encode(archive);
    await File(outPath).writeAsBytes(zipData, flush: true);
    return outPath;
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    // 간단한 기본 구현: 앱 문서 폴더의 labels_import.json을 읽어 복원
    // (파일 선택 UI를 붙이고 싶다면 별도 구현으로 대체)
    final f = await _docFile('labels_import.json');
    if (!await f.exists()) return const [];

    final text = await f.readAsString();
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();

    final models = <LabelModel>[];
    for (final e in list) {
      final modeName = e['mode'] as String?;
      final mode = modeName != null
          ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => LabelingMode.singleClassification)
          : LabelingMode.singleClassification;
      models.add(LabelModelConverter.fromJson(mode, e)); // ← 래퍼 전체 전달
    }
    return models;
  }

  // ==============================
  // 📌 Data Read
  // ==============================

  /// Native: filePath 필수. 해당 경로에서 바이트를 읽는다.
  @override
  Future<Uint8List> readDataBytes(DataInfo info) async {
    final path = info.filePath?.trim();
    if (path == null || path.isEmpty) {
      throw ArgumentError('Native read requires a valid filePath for "${info.fileName}".');
    }
    return await File(path).readAsBytes();
  }

  /// Native: 경로 기반 접근이 가능하므로 filePath를 그대로 반환(또는 file://).
  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) async {
    return info.filePath; // Image.file 등에서 바로 사용 가능
  }

  /// Native: 해제할 ObjectURL이 없음 (no-op).
  @override
  Future<void> revokeLocalObjectUrl(String url) async {
    // no-op
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Cache Management
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> clearAllCache() async {
    // 라벨 관련 파일만 정리(설계도/레지스트리 파일은 보존)
    final dir = await getApplicationDocumentsDirectory();
    final entries = dir.listSync();

    for (final fsEntity in entries) {
      if (fsEntity is! File) continue;
      final name = p.basename(fsEntity.path);
      final isLabelFile = name.startsWith('labels_project_') && name.endsWith('.json');
      final isImportFile = name == 'labels_import.json';
      if (isLabelFile || isImportFile) {
        try {
          await fsEntity.delete();
        } catch (_) {}
      }
    }

    // 임시 폴더의 ZIP 정리(선택)
    final tmp = Directory.systemTemp;
    for (final fsEntity in tmp.listSync()) {
      if (fsEntity is! File) continue;
      final name = p.basename(fsEntity.path);
      if (name.endsWith('_labels.zip')) {
        try {
          await fsEntity.delete();
        } catch (_) {}
      }
    }
  }

  // ==============================
  // 📌 Object Upload (Cloud 우선)
  // ==============================
  Future<File> _fileFromKey(String objectKey) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, objectKey));
    await file.parent.create(recursive: true);
    return file;
  }

  @override
  Future<String> uploadText(String objectKey, String text, {String? contentType}) async {
    final f = await _fileFromKey(objectKey);
    await f.writeAsString(text);
    return f.path;
  }

  @override
  Future<String> uploadBase64(String objectKey, String rawBase64, {String? contentType}) async {
    final f = await _fileFromKey(objectKey);
    await f.writeAsBytes(base64Decode(rawBase64));
    return f.path;
  }

  @override
  Future<String> uploadBytes(String objectKey, Uint8List bytes, {String? contentType}) async {
    final f = await _fileFromKey(objectKey);
    await f.writeAsBytes(bytes);
    return f.path;
  }

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
