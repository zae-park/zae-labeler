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
import '../../features/label/models/label_model.dart';
import 'interface_storage_helper.dart';

/// Cloud(Firebase Firestore + Storage) 기반 StorageHelper
/// - Firestore: 프로젝트/라벨 CRUD
/// - Firebase Storage: labels.json (라벨 일괄 내보내기/가져오기)
/// - 라벨 직렬화 스키마(통일): { data_id, data_path, labeled_at, mode(name), label_data }
class CloudStorageHelper implements StorageHelperInterface {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final fb_storage.FirebaseStorage storage = fb_storage.FirebaseStorage.instance;

  /// 인터페이스에는 없지만, Cloud import 시 프로젝트 컨텍스트가 필요하므로
  /// 편의상 현재 활성 프로젝트를 지정할 수 있게 제공.
  String? _activeProjectId;
  void setActiveProject(String projectId) => _activeProjectId = projectId;

  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint("❌ FirebaseAuth.currentUser is null");
      throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _projectsCol => firestore.collection('users').doc(_uid).collection('projects');

  CollectionReference<Map<String, dynamic>> _labelsCol(String projectId) => _projectsCol.doc(projectId).collection('labels');

  String _labelsJsonPath(String projectId) => 'users/$_uid/projects/$projectId/labels/latest.json';

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project List / Config (설계도 스냅샷)
  //  - Cloud에서는 프로젝트 문서를 users/{uid}/projects 에 저장
  //  - saveProjectConfig는 saveProjectList와 동일 동작(설계도 스냅샷)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveProjectList(List<Project> projects) async {
    debugPrint("[CloudStorageHelper] ▶️ saveProjectList: ${projects.length}개");
    final batch = firestore.batch();

    for (final project in projects) {
      final docRef = _projectsCol.doc(project.id);

      final json = project.toJson(includeLabels: false);
      // 필요 시 DataInfo 슬림화 가능(현재는 그대로 저장)
      json['dataInfos'] = project.dataInfos.map((e) => e.toJson()).toList();

      batch.set(docRef, json, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint("[CloudStorageHelper] ✅ saveProjectList 완료");
  }

  @override
  Future<List<Project>> loadProjectList() async {
    debugPrint("[CloudStorageHelper] 📥 loadProjectList");
    final snap = await _projectsCol.get();
    final list = snap.docs.map((d) => Project.fromJson(d.data())).toList();
    debugPrint("[CloudStorageHelper] ✅ loadProjectList: ${list.length}개");
    return list;
  }

  @override
  Future<void> saveProjectConfig(List<Project> projects) => saveProjectList(projects);

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async => throw UnimplementedError("Cloud: loadProjectFromConfig는 사용되지 않습니다.");

  @override
  Future<String> downloadProjectConfig(Project project) async {
    // 라벨 제외 + 필요 시 DataInfo 슬림화
    final j = project.toJson(includeLabels: false);
    j['dataInfos'] = (j['dataInfos'] as List).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return {'id': m['id'], 'fileName': m['fileName']};
    }).toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert(j);

    if (kIsWeb) {
      final blob = html.Blob([jsonString]);
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
      'mode': labelModel.mode.name, // ★ name 사용 (toString() 금지)
      'label_data': LabelModelConverter.toJson(labelModel),
    };
    await doc.set(map, SetOptions(merge: true));
    debugPrint("[CloudStorageHelper] 💾 saveLabelData: $projectId/$dataId");
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode modeHint) async {
    final doc = await _labelsCol(projectId).doc(dataId).get();
    if (!doc.exists) {
      debugPrint("[CloudStorageHelper] ⚠️ 라벨 없음 → 초기 생성");
      return LabelModelFactory.createNew(modeHint, dataId: dataId);
    }
    final map = doc.data()!;
    final modeName = map['mode'] as String?;
    final mode = modeName != null ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => modeHint) : modeHint;

    // ★ 래퍼 전체(Map) 전달
    return LabelModelConverter.fromJson(mode, map);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Project-wide Label IO (Firestore)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    debugPrint("[CloudStorageHelper] 💾 saveAllLabels: ${labels.length}개");
    final col = _labelsCol(projectId);
    final batch = firestore.batch();

    for (final m in labels) {
      final doc = col.doc(m.dataId);
      batch.set(
          doc,
          {
            'data_id': m.dataId,
            'data_path': m.dataPath,
            'labeled_at': m.labeledAt.toIso8601String(),
            'mode': m.mode.name, // ★ name
            'label_data': LabelModelConverter.toJson(m),
          },
          SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint("[CloudStorageHelper] ✅ saveAllLabels 완료");
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    debugPrint("[CloudStorageHelper] 📥 loadAllLabelModels: $projectId");
    final snap = await _labelsCol(projectId).get();

    final out = <LabelModel>[];
    for (final d in snap.docs) {
      final map = d.data();
      final modeName = map['mode'] as String?;
      final mode = modeName != null
          ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => LabelingMode.singleClassification)
          : LabelingMode.singleClassification;
      // ★ 래퍼 전체(Map) 전달
      out.add(LabelModelConverter.fromJson(mode, map));
    }
    debugPrint("[CloudStorageHelper] ✅ loadAllLabelModels: ${out.length}개");
    return out;
  }

  @override
  Future<void> deleteProjectLabels(String projectId) async {
    debugPrint("[CloudStorageHelper] ❌ deleteProjectLabels: $projectId");
    final snap = await _labelsCol(projectId).get();
    final batch = firestore.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    debugPrint("[CloudStorageHelper] ✅ deleteProjectLabels 완료");
  }

  @override
  Future<void> deleteProject(String projectId) async {
    debugPrint("[CloudStorageHelper] ❌ deleteProject: $projectId");
    await deleteProjectLabels(projectId);
    await _projectsCol.doc(projectId).delete();
    debugPrint("[CloudStorageHelper] ✅ deleteProject 완료");
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Label Import/Export (Firebase Storage)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async {
    // 1) labels.json 직렬화
    final entries = labelModels
        .map((m) => <String, dynamic>{
              'data_id': m.dataId,
              'data_path': m.dataPath,
              'labeled_at': m.labeledAt.toIso8601String(),
              'mode': m.mode.name, // 혼합 모드 방어
              'label_data': LabelModelConverter.toJson(m),
            })
        .toList();
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(entries)));

    // 2) Storage 경로
    final path = _labelsJsonPath(project.id);
    final ref = storage.ref().child(path);

    // 3) 업로드
    await ref.putData(jsonBytes, fb_storage.SettableMetadata(contentType: 'application/json; charset=utf-8'));

    // 4) 다운로드 URL 반환 (필요 시 gs:// 경로를 반환하도록 변경 가능)
    final url = await ref.getDownloadURL();
    debugPrint("[CloudStorageHelper] ☁️ labels.json 업로드 완료 → $url");
    return url;
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    // ⚠️ 인터페이스 제약: projectId 없이 호출됨 → activeProject 기반으로 동작
    final projectId = _activeProjectId;
    if (projectId == null || projectId.isEmpty) {
      throw StateError(
        "Cloud.importAllLabels(): activeProjectId가 설정되지 않았습니다. "
        "사용 전 cloudHelper.setActiveProject(projectId)를 호출하세요.",
      );
    }

    final path = _labelsJsonPath(projectId);
    final ref = storage.ref().child(path);

    // 최신 labels.json 다운로드
    final data = await ref.getData(10 * 1024 * 1024); // 10MB 제한 (필요시 조정)
    if (data == null) return const [];

    final text = utf8.decode(data);
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();

    final models = <LabelModel>[];
    for (final e in list) {
      final modeName = e['mode'] as String?;
      final mode = modeName != null
          ? LabelingMode.values.firstWhere((m) => m.name == modeName, orElse: () => LabelingMode.singleClassification)
          : LabelingMode.singleClassification;
      models.add(LabelModelConverter.fromJson(mode, e)); // 래퍼 전체 전달
    }
    debugPrint("[CloudStorageHelper] ☁️ labels.json 로드 완료: ${models.length}개");
    return models;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📌 Cache (Cloud는 로컬 캐시 의미 없음)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> clearAllCache() async {}

  // ─────────────────────────────────────────────────────────────────────────
  // 🔧 편의 메서드(인터페이스 외) — 선택 사용
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveSingleProject(Project project) async {
    final doc = _projectsCol.doc(project.id);
    final json = project.toJson(includeLabels: false);
    json['dataInfos'] = project.dataInfos.map((e) => e.toJson()).toList();
    await doc.set(json, SetOptions(merge: true));
  }

  Future<void> deleteSingleProject(String projectId) async => await deleteProject(projectId);
}
