// lib/src/platform_helpers/storage/cloud_storage_helper.dart
import 'dart:convert';
import 'dart:typed_data'; // ✅ for Uint8List
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/models/project/project_model.dart';
import '../../core/models/data/data_info.dart';
import '../../core/models/label/label_model.dart';
import 'interface_storage_helper.dart';

/// Cloud(Firebase Firestore + Firebase Storage) 기반 StorageHelper 구현체.
///
/// - 옵션 A(현 적용): 프로젝트 저장/다운로드 시 DataInfo를
///   `{id,fileName,filePath,mimeType}`로 **슬림화**하여 직렬화한다.
///   (대용량/휘발 필드인 base64Content/objectUrl은 저장하지 않음)
///
/// - 옵션 B(문서화): 프로젝트 문서를 더 작게 유지하고 싶다면
///   `users/{uid}/projects/{projectId}/metadata/dataIndex` 같은 별도 문서에
///   `{ data_id: {filePath, mimeType} }` 맵을 저장해두고,
///   로드 시 이 맵을 읽어 각 `DataInfo`에 `copyWith(filePath,mimeType)`로 **합성**한다.
///   대규모 프로젝트에서 확장 메타 관리가 쉬워진다.
///
/// ### 책임
/// - **Firestore**: 프로젝트/라벨 CRUD 영속화
/// - **Firebase Storage**: `labels.json` 스냅샷 업/다운로드(옵션)
/// - 모든 라벨 직렬화는 **표준 래퍼 스키마**를 사용:
///   {
///     "data_id": "<데이터 ID>",
///     "data_path": "<원본 경로/파일명|null>",
///     "labeled_at": "YYYY-MM-DDTHH:mm:ss.sssZ",
///     "mode": "<LabelingMode.name>",
///     "label_data": { ... } // LabelModel.toJson()
///   }
///
/// ### 설계 메모
/// - Firestore 문서 크기 제한(1MB), 배치 쓰기 제한(500)을 고려:
///   - 프로젝트 저장 시 **DataInfo는 toSlimJson()**으로 직렬화
///   - 라벨 일괄 저장/삭제는 **청크(Chunk)** 로 나눠 처리
/// - `LabelModelConverter`에는 **래퍼(Map 전체)** 를 전달
///
/// ### 보안 규칙(권장 예시)
/// - Firestore: `users/{uid}/projects/{projectId}` 및 `.../labels/{dataId}`
///   - `allow read, write: if request.auth.uid == uid;`
/// - Storage: `users/{uid}/projects/{projectId}/labels/latest.json`
///   - 동일한 `uid` 조건으로 제한
class CloudStorageHelper implements StorageHelperInterface {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final fb_storage.FirebaseStorage storage = fb_storage.FirebaseStorage.instance;

  /// (선택) Import 시 프로젝트 컨텍스트를 지정하기 위한 편의 필드.
  String? _activeProjectId;

  /// 현재 활성 프로젝트 ID를 지정합니다. (importAllLabels에 필요)
  void setActiveProject(String projectId) => _activeProjectId = projectId;

  /// 현재 로그인된 Firebase 사용자 UID를 반환합니다.
  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');
    }
    return user.uid;
  }

  /// 현재 사용자 컬렉션 하위의 프로젝트 컬렉션 레퍼런스
  CollectionReference<Map<String, dynamic>> get _projectsCol => firestore.collection('users').doc(_uid).collection('projects');

  /// 특정 프로젝트의 라벨 컬렉션 레퍼런스
  CollectionReference<Map<String, dynamic>> _labelsCol(String projectId) => _projectsCol.doc(projectId).collection('labels');

  /// Storage의 `labels.json` 저장 경로
  String _labelsJsonPath(String projectId) => 'users/$_uid/projects/$projectId/labels/latest.json';

  // ─────────────────────────────────────────────────────────────────────────
  // 🔧 유틸: Firestore 배치 500건 제한 대응
  // ─────────────────────────────────────────────────────────────────────────

  Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project List / Config (설계도 스냅샷)
  // ─────────────────────────────────────────────────────────────────────────

  /// 사용자의 프로젝트 리스트를 Firestore에 저장합니다.
  ///
  /// - 저장 위치: `users/{uid}/projects/{projectId}`
  /// - **DataInfo는 toSlimJson()**으로 직렬화({id,fileName,filePath,mimeType})
  /// - 라벨은 포함하지 않습니다(라벨은 labels 서브컬렉션에서 관리)
  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final batch = firestore.batch();
    for (final project in projects) {
      batch.set(_projectsCol.doc(project.id), _projectDoc(project), SetOptions(merge: true));
      debugPrint(
        '[CloudSave] ${project.id} dataInfos='
        '${project.dataInfos.map((d) => "(${d.fileName},path=${d.filePath != null},b64=${(d.base64Content?.isNotEmpty ?? false)})").join(", ")}',
      );
    }
    await batch.commit();
  }

  /// Firestore에서 사용자의 프로젝트 리스트를 로드합니다.
  /// 프로젝트 문서 1개만 병합 저장합니다(라벨 제외).
  @override
  Future<void> saveProject(Project project) => _projectsCol.doc(project.id).set(_projectDoc(project), SetOptions(merge: true));

  /// 프로젝트 문서 직렬화. 업로드 성공(경로 있음) → 슬림 저장, 실패 → base64 보존 저장.
  Map<String, dynamic> _projectDoc(Project project) {
    final j = project.toJson(includeLabels: false);
    j['dataInfos'] = project.dataInfos.map((e) {
      final hasPath = (e.filePath?.isNotEmpty ?? false);
      final hasB64 = (e.base64Content?.isNotEmpty ?? false);
      return hasPath ? e.slimmedForPersist().toSlimJson() : (hasB64 ? e.toJson() : e.slimmedForPersist().toSlimJson());
    }).toList();
    return j;
  }

  @override
  Future<List<Project>> loadProjectList() async {
    final snap = await _projectsCol.get();
    return snap.docs.map((d) => Project.fromJson(d.data())).toList();
  }

  /// Cloud 환경에서의 설계도 스냅샷 저장은 프로젝트 리스트 저장과 동일하게 처리
  @override
  Future<void> saveProjectConfig(List<Project> projects) => saveProjectList(projects);

  /// Cloud 환경에서는 외부 JSON 문자열로부터 복원하지 않음
  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async => throw UnimplementedError("Cloud: loadProjectFromConfig는 사용되지 않습니다.");

  /// 단일 프로젝트의 설계도(JSON, 라벨 제외)를 브라우저 다운로드로 제공 (Web 전용)
  @override
  Future<String> downloadProjectConfig(Project project) async {
    final j = project.toJson(includeLabels: false);
    j['dataInfos'] = (j['dataInfos'] as List).map((e) => DataInfo.fromJson((e as Map).cast<String, dynamic>()).toSlimJson()).toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert(j);
    if (kIsWeb) {
      final blob = html.Blob([jsonString], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', '${project.name}_config.json')
        ..click();
      html.Url.revokeObjectUrl(url);
      return "${project.name}_config.json";
    }
    throw UnimplementedError("downloadProjectConfig()는 Web에서만 지원됩니다.");
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Single Label Data IO (CRUD in Firestore)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    final doc = _labelsCol(projectId).doc(dataId);
    final map = {
      'data_id': dataId,
      'data_path': dataPath,
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'mode': labelModel.mode.name,
      'label_data': LabelModelConverter.toJson(labelModel),
    };
    await doc.set(map, SetOptions(merge: true));
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode modeHint) async {
    final doc = await _labelsCol(projectId).doc(dataId).get();
    if (!doc.exists) {
      return LabelModelFactory.createNew(modeHint, dataId: dataId);
    }
    final map = doc.data()!;
    final modeName = map['mode'] as String?;
    final mode = modeName != null ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => modeHint) : modeHint;
    return LabelModelConverter.fromJson(mode, map);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project-wide Label IO (Firestore)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    for (final chunk in _chunks(labels, 450)) {
      final col = _labelsCol(projectId);
      final batch = firestore.batch();
      for (final m in chunk) {
        final doc = col.doc(m.dataId);
        batch.set(doc, {
          'data_id': m.dataId,
          'data_path': m.dataPath,
          'labeled_at': m.labeledAt.toIso8601String(),
          'mode': m.mode.name,
          'label_data': LabelModelConverter.toJson(m),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    final snap = await _labelsCol(projectId).get();
    final out = <LabelModel>[];
    for (final d in snap.docs) {
      final map = d.data();
      final modeName = map['mode'] as String?;
      final mode = modeName != null
          ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => LabelingMode.singleClassification)
          : LabelingMode.singleClassification;
      out.add(LabelModelConverter.fromJson(mode, map));
    }
    return out;
  }

  @override
  Future<void> deleteProjectLabels(String projectId) async {
    Query<Map<String, dynamic>> q = _labelsCol(projectId).limit(500);
    while (true) {
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      final batch = firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 500) break;
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await deleteProjectLabels(projectId);
    await _projectsCol.doc(projectId).delete();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Label Import/Export (Firebase Storage)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async {
    final models = labelModels.isEmpty ? await loadAllLabelModels(project.id) : labelModels;

    final entries = models
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
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(entries)));

    final path = _labelsJsonPath(project.id);
    final ref = storage.ref().child(path);

    await ref.putData(jsonBytes, fb_storage.SettableMetadata(contentType: 'application/json; charset=utf-8'));
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    final projectId = _activeProjectId;
    if (projectId == null || projectId.isEmpty) {
      throw StateError(
        "Cloud.importAllLabels(): activeProjectId가 없습니다. "
        "사용 전 cloudHelper.setActiveProject(projectId)를 호출하세요.",
      );
    }

    final path = _labelsJsonPath(projectId);
    final ref = storage.ref().child(path);
    final data = await ref.getData(10 * 1024 * 1024); // 10MB
    if (data == null) return const [];

    final text = utf8.decode(data);
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();

    final models = <LabelModel>[];
    for (final e in list) {
      final modeName = e['mode'] as String?;
      final mode = modeName != null
          ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => LabelingMode.singleClassification)
          : LabelingMode.singleClassification;
      models.add(LabelModelConverter.fromJson(mode, e)); // 래퍼 전체
    }
    return models;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📖 Data Read helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Firebase Storage에서 텍스트(UTF-8) 읽기
  Future<String?> readTextAt(String path, {int maxSizeBytes = 10 * 1024 * 1024}) async {
    try {
      final data = await storage.ref().child(path).getData(maxSizeBytes);
      if (data == null) return null;
      return utf8.decode(data);
    } catch (e) {
      debugPrint("[CloudStorageHelper.readTextAt] $path 읽기 실패: $e");
      return null;
    }
  }

  /// Firebase Storage에서 JSON 읽기 → Map
  Future<Map<String, dynamic>?> readJsonAt(String path, {int maxSizeBytes = 10 * 1024 * 1024}) async {
    final text = await readTextAt(path, maxSizeBytes: maxSizeBytes);
    if (text == null || text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint("[CloudStorageHelper.readJsonAt] $path JSON 파싱 실패: $e");
      return null;
    }
  }

  /// Firebase Storage에서 바이너리 읽기
  Future<Uint8List?> readBytesAt(String path, {int maxSizeBytes = 20 * 1024 * 1024}) async {
    try {
      return await storage.ref().child(path).getData(maxSizeBytes);
    } catch (e) {
      debugPrint("[CloudStorageHelper.readBytesAt] $path 읽기 실패: $e");
      return null;
    }
  }

  /// (선택) 이미지 Base64로 읽기
  Future<String?> readImageBase64At(String path, {int maxSizeBytes = 20 * 1024 * 1024}) async {
    final bytes = await readBytesAt(path, maxSizeBytes: maxSizeBytes);
    if (bytes == null) return null;
    return base64Encode(bytes); // data:image/*;base64, ... 는 뷰어에서 접두사 붙여도 됨
  }

  // ==============================
  // 📌 Data Read
  // ==============================

  /// Cloud: http(s) URL/gs:///상대경로를 지원. 필요 시 SDK로 URL 해석.
  @override
  Future<Uint8List> readDataBytes(DataInfo info) async {
    final raw = info.filePath?.trim();
    if (raw == null || raw.isEmpty) {
      throw ArgumentError('Cloud read requires filePath.');
    }
    final url = await _resolveToDownloadUrl(raw);
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) return resp.bodyBytes;
    throw StateError('HTTP ${resp.statusCode} while fetching $url');
  }

  Future<String> _resolveToDownloadUrl(String raw) async {
    // http(s)면 그대로
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // gs://bucket/path or Firebase Storage 상대경로
    try {
      final ref = raw.startsWith('gs://') ? storage.refFromURL(raw) : storage.ref(raw);
      return await ref.getDownloadURL();
    } catch (_) {
      rethrow;
    }
  }

  /// Cloud: 웹이 아닌 경우 보통 Blob URL 불필요. 필요 시 다운로드 URL 반환.
  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) async {
    final raw = info.filePath?.trim();
    if (raw == null || raw.isEmpty) return null;
    return await _resolveToDownloadUrl(raw);
  }

  /// Cloud: 해제할 ObjectURL 없음 (no-op).
  @override
  Future<void> revokeLocalObjectUrl(String url) async {
    // no-op
  }

  // ==============================
  // 📌 Cache (Cloud는 로컬 캐시 의미 없음)
  // ==============================

  @override
  Future<void> clearAllCache() async {}

  // ==============================
  // 📌 Object Upload (Cloud 우선)
  // ==============================
  @override
  Future<String> uploadText(String objectKey, String text, {String? contentType}) async {
    final ref = storage.ref().child(objectKey);
    final bytes = Uint8List.fromList(utf8.encode(text));
    await ref.putData(bytes, fb_storage.SettableMetadata(contentType: contentType ?? 'text/plain; charset=utf-8'));
    return objectKey; // raw 경로(키)를 filePath로 사용
  }

  @override
  Future<String> uploadBase64(String objectKey, String rawBase64, {String? contentType}) async {
    final ref = storage.ref().child(objectKey);
    final bytes = base64Decode(rawBase64);
    await ref.putData(bytes, fb_storage.SettableMetadata(contentType: contentType ?? 'application/octet-stream'));
    return objectKey;
  }

  @override
  Future<String> uploadBytes(String objectKey, Uint8List bytes, {String? contentType}) async {
    final ref = storage.ref().child(objectKey);
    await ref.putData(bytes, fb_storage.SettableMetadata(contentType: contentType ?? 'application/octet-stream'));
    return objectKey;
  }

  // ==============================
  // 📌 Project Upload (Cloud 우선)
  // ==============================

  String _projectObjectPath(String projectId, String objectKey) => 'users/$_uid/projects/$projectId/$objectKey'; // ✅ 규칙과 일치

  @override
  Future<String> uploadProjectText(String projectId, String objectKey, String text, {String? contentType}) async {
    final full = _projectObjectPath(projectId, objectKey);
    final ref = storage.ref().child(full);
    await ref.putData(Uint8List.fromList(utf8.encode(text)), fb_storage.SettableMetadata(contentType: contentType ?? 'text/plain; charset=utf-8'));
    return full; // 이 값을 DataInfo.filePath로 사용
  }

  @override
  Future<String> uploadProjectBase64(String projectId, String objectKey, String rawBase64, {String? contentType}) async {
    final full = _projectObjectPath(projectId, objectKey);
    final ref = storage.ref().child(full);
    await ref.putData(base64Decode(rawBase64), fb_storage.SettableMetadata(contentType: contentType ?? 'application/octet-stream'));
    return full;
  }

  @override
  Future<String> uploadProjectBytes(String projectId, String objectKey, Uint8List bytes, {String? contentType}) async {
    final full = _projectObjectPath(projectId, objectKey);
    final ref = storage.ref().child(full);
    await ref.putData(bytes, fb_storage.SettableMetadata(contentType: contentType ?? 'application/octet-stream'));
    return full;
  }

  // (선택) 업로드 재시도 시간 단축: 네트워크 이슈 시 빠르게 실패하도록
  CloudStorageHelper() {
    storage.setMaxUploadRetryTime(const Duration(seconds: 15));
    storage.setMaxOperationRetryTime(const Duration(seconds: 20));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 🔧 편의 메서드(인터페이스 외) — 선택 사용
  // ─────────────────────────────────────────────────────────────────────────
}
