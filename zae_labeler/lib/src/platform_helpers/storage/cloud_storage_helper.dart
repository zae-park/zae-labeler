// lib/src/utils/cloud_storage_helper.dart
import 'dart:convert';
import 'dart:typed_data';

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
/// ### 책임
/// - **Firestore**: 프로젝트/라벨 CRUD 영속화
/// - **Firebase Storage**: `labels.json` 스냅샷 업/다운로드(옵션)
/// - 모든 라벨 직렬화는 **표준 래퍼 스키마**를 사용:
///   ```json
///   {
///     "data_id": "<데이터 ID>",
///     "data_path": "<원본 경로/파일명|null>",
///     "labeled_at": "YYYY-MM-DDTHH:mm:ss.sssZ",
///     "mode": "<LabelingMode.name>",
///     "label_data": { ... } // LabelModel.toJson()
///   }
///   ```
///
/// ### 설계 메모
/// - Firestore 문서 크기 제한(1MB)과 배치 쓰기 제한(500건)을 고려하여
///   - 프로젝트 저장 시 **DataInfo는 {id, fileName}로 슬림화**하여 저장
///   - 라벨 일괄 저장/삭제는 **청크(Chunk)** 로 나누어 처리
/// - `LabelModelConverter`에는 **래퍼(Map) 전체**를 전달하여 모드/메타와 동기화
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
  /// 인터페이스에는 없지만, Storage에서 `latest.json`을 읽을 때 필요.
  String? _activeProjectId;

  /// 현재 활성 프로젝트 ID를 지정합니다. (importAllLabels에 필요)
  void setActiveProject(String projectId) => _activeProjectId = projectId;

  /// 현재 로그인된 Firebase 사용자 UID를 반환합니다.
  /// 로그인되지 않은 경우 예외를 발생시킵니다.
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

  /// 리스트를 [size] 크기의 청크로 나눠 이터레이션합니다.
  /// Firestore 배치 제한(500건)을 회피할 때 사용합니다.
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
  /// - **DataInfo는 {id, fileName}로 슬림화**하여 저장(대용량/base64 금지)
  /// - 라벨은 포함하지 않습니다(라벨은 별도 라벨 컬렉션에서 관리)
  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final batch = firestore.batch();
    for (final project in projects) {
      final docRef = _projectsCol.doc(project.id);
      final j = project.toJson(includeLabels: false);
      j['dataInfos'] = project.dataInfos.map((e) => {'id': e.id, 'fileName': e.fileName}).toList();
      batch.set(docRef, j, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Firestore에서 사용자의 프로젝트 리스트를 로드합니다.
  ///
  /// - 라벨은 포함되지 않으며, 필요한 경우 별도의 라벨 로딩 API를 사용합니다.
  @override
  Future<List<Project>> loadProjectList() async {
    final snap = await _projectsCol.get();
    return snap.docs.map((d) => Project.fromJson(d.data())).toList();
  }

  /// Cloud 환경에서의 설계도 스냅샷 저장은 프로젝트 리스트 저장과 동일하게 처리합니다.
  @override
  Future<void> saveProjectConfig(List<Project> projects) => saveProjectList(projects);

  /// Cloud 환경에서는 외부 JSON 문자열로부터 복원하지 않습니다.
  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async => throw UnimplementedError("Cloud: loadProjectFromConfig는 사용되지 않습니다.");

  /// 단일 프로젝트의 설계도(JSON, 라벨 제외)를 브라우저 다운로드로 제공합니다.
  ///
  /// - Web 전용: `download` 속성으로 저장 트리거
  /// - Native에서는 미지원
  @override
  Future<String> downloadProjectConfig(Project project) async {
    final j = project.toJson(includeLabels: false);
    j['dataInfos'] = (j['dataInfos'] as List).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return {'id': m['id'], 'fileName': m['fileName']};
    }).toList();

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

  /// 특정 데이터(=dataId)의 라벨을 Firestore에 저장/갱신합니다.
  ///
  /// - 경로: `users/{uid}/projects/{projectId}/labels/{dataId}`
  /// - **mode는 `.name`으로 저장**하고, `label_data`는 모델의 toJson 결과를 그대로 담습니다.
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

  /// 특정 데이터(=dataId)의 라벨을 Firestore에서 로드합니다.
  ///
  /// - 없으면 `modeHint` 기반의 **초기 라벨**을 만들어 반환합니다.
  /// - 복원 시 **래퍼(Map 전체)** 를 Converter에 전달합니다.
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

  /// 프로젝트의 모든 라벨을 Firestore에 **일괄 저장**합니다.
  ///
  /// - Firestore 배치 제한(500)을 고려해 **청크(450)** 단위로 커밋합니다.
  /// - 각 라벨은 표준 래퍼 스키마로 직렬화하여 저장합니다.
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    for (final chunk in _chunks(labels, 450)) {
      final col = _labelsCol(projectId);
      final batch = firestore.batch();
      for (final m in chunk) {
        final doc = col.doc(m.dataId);
        batch.set(
          doc,
          {
            'data_id': m.dataId,
            'data_path': m.dataPath,
            'labeled_at': m.labeledAt.toIso8601String(),
            'mode': m.mode.name,
            'label_data': LabelModelConverter.toJson(m),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  /// 프로젝트의 모든 라벨을 Firestore에서 로드하여 모델로 복원합니다.
  ///
  /// - 각 문서의 `mode`를 `.name` 기준으로 파싱합니다.
  /// - Converter에는 **래퍼(Map 전체)** 를 전달합니다.
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

  /// 프로젝트의 모든 라벨 문서를 **일괄 삭제**합니다.
  ///
  /// - Firestore 읽기/쓰기 비용을 줄이기 위해 500개 단위로 페이지네이션 삭제합니다.
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

  /// 프로젝트 문서 + 라벨 서브컬렉션을 모두 삭제합니다.
  ///
  /// - 라벨을 먼저 삭제한 뒤, 프로젝트 문서를 제거합니다.
  @override
  Future<void> deleteProject(String projectId) async {
    await deleteProjectLabels(projectId);
    await _projectsCol.doc(projectId).delete();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Label Import/Export (Firebase Storage)
  // ─────────────────────────────────────────────────────────────────────────

  /// 프로젝트의 라벨 전체를 `labels.json`으로 직렬화해 **Firebase Storage**에 업로드합니다.
  ///
  /// - 경로: `users/{uid}/projects/{projectId}/labels/latest.json`
  /// - 반환: 다운로드 URL (필요 시 `gs://` 경로로 변경 가능)
  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async {
    final models = labelModels.isEmpty ? await loadAllLabelModels(project.id) : labelModels;

    final entries = models
        .map((m) => <String, dynamic>{
              'data_id': m.dataId,
              'data_path': m.dataPath,
              'labeled_at': m.labeledAt.toIso8601String(),
              'mode': m.mode.name,
              'label_data': LabelModelConverter.toJson(m),
            })
        .toList();
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(entries)));

    final path = _labelsJsonPath(project.id);
    final ref = storage.ref().child(path);

    await ref.putData(jsonBytes, fb_storage.SettableMetadata(contentType: 'application/json; charset=utf-8'));
    final url = await ref.getDownloadURL();
    return url;
  }

  /// Firebase Storage에 저장된 `labels.json`을 다운로드해 라벨 목록으로 복원합니다.
  ///
  /// - 사용 전 `setActiveProject(projectId)` 호출로 프로젝트 컨텍스트를 지정해야 합니다.
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
  // 📌 Cache (Cloud는 로컬 캐시 의미 없음)
  // ─────────────────────────────────────────────────────────────────────────

  /// Cloud 구현에서는 로컬 캐시를 사용하지 않으므로 no-op입니다.
  @override
  Future<void> clearAllCache() async {}

  // ─────────────────────────────────────────────────────────────────────────
  // 🔧 편의 메서드(인터페이스 외) — 선택 사용
  // ─────────────────────────────────────────────────────────────────────────

  /// 단일 프로젝트를 병합 저장(라벨 제외)합니다.
  /// - DataInfo는 슬림화하여 저장합니다.
  Future<void> saveSingleProject(Project project) async {
    final doc = _projectsCol.doc(project.id);
    final j = project.toJson(includeLabels: false);
    j['dataInfos'] = project.dataInfos.map((e) => {'id': e.id, 'fileName': e.fileName}).toList();
    await doc.set(j, SetOptions(merge: true));
  }

  /// 단일 프로젝트 삭제(라벨 포함) 편의 메서드입니다.
  Future<void> deleteSingleProject(String projectId) async => await deleteProject(projectId);
}
