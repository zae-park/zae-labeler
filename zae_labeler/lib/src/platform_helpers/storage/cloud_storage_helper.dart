// lib/src/utils/cloud_storage_helper.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/models/project_model.dart';
import '../../core/models/data_model.dart';
import '../../core/models/label_model.dart';
import 'interface_storage_helper.dart';

/// 🔒 Cloud 기반 StorageHelper 구현체 (Firebase Firestore 기반)
/// - 플랫폼이 Web이며 Firebase 로그인된 사용자의 프로젝트 및 라벨 데이터를 Firestore에 저장/불러오기 위해 사용됩니다.
/// - StorageHelperInterface 를 구현합니다.
class CloudStorageHelper implements StorageHelperInterface {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint("❌ FirebaseAuth.currentUser is null");
      throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');
    }
    return user.uid;
  }

  /// 📌 [saveProjectList]
  /// 사용자가 생성한 모든 프로젝트 리스트를 Firestore에 저장합니다.
  /// - 호출 위치: 프로젝트 생성/수정 후 전체 리스트 저장 시
  /// - 저장 위치: users/{uid}/projects/{project.id}
  @override
  Future<void> saveProjectList(List<Project> projects) async {
    debugPrint("[CloudStorageHelper] ▶️ saveProjectList 호출됨 - 총 ${projects.length}개 프로젝트");
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');

    final uid = user.uid;
    final batch = firestore.batch();
    final projectsRef = firestore.collection('users').doc(uid).collection('projects');

    for (var project in projects) {
      final docRef = projectsRef.doc(project.id);
      final json = project.toJson(includeLabels: false);

      json['dataInfos'] = project.dataInfos.map((e) => e.toJson()).toList();

      debugPrint("[CloudStorageHelper] 💾 저장할 프로젝트: ${project.id}, ${project.name}");
      batch.set(docRef, json);
    }

    await batch.commit();
    debugPrint("[CloudStorageHelper] ✅ saveProjectList 완료");
  }

  /// 📌 [loadProjectList]
  /// 현재 로그인된 사용자의 모든 프로젝트 리스트를 Firestore에서 로드합니다.
  /// - 호출 위치: 앱 초기 로딩 시 프로젝트 리스트 조회용
  @override
  Future<List<Project>> loadProjectList() async {
    debugPrint("[CloudStorageHelper] 📥 loadProjectList 호출됨");
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').get();
    final projects = snapshot.docs.map((doc) => Project.fromJson(doc.data())).toList();
    debugPrint("[CloudStorageHelper] ✅ loadProjectList 완료: ${projects.length}개 로드됨");
    return projects;
  }

  /// 📌 [saveSingleProject]
  /// 단일 프로젝트를 Firestore에 저장합니다 (병합 저장).
  /// - 호출 위치: 프로젝트 수정 시 단건 업데이트
  Future<void> saveSingleProject(Project project) async {
    debugPrint("[CloudStorageHelper] 💾 saveSingleProject 호출됨: ${project.id}, ${project.name}");
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(project.id);
    final json = project.toJson(includeLabels: true);

    // if (project.dataInfos.isNotEmpty) {

    //   json['dataInfos'] = project.dataInfos.map((e) => e.toJson()).toList();
    // }
    debugPrint("[CloudStorageHelper] 💾 dataInfos: ${project.dataInfos}");
    json['dataInfos'] = project.dataInfos.map((e) => e.toJson()).toList();
    await docRef.set(json, SetOptions(merge: true));
    debugPrint("[CloudStorageHelper] ✅ saveSingleProject 완료: ${project.id}");
  }

  /// 📌 [deleteSingleProject]
  /// Firestore에서 특정 프로젝트 문서를 삭제합니다.
  /// - 호출 위치: 프로젝트 삭제 시
  Future<void> deleteSingleProject(String projectId) async {
    debugPrint("[CloudStorageHelper] ❌ deleteSingleProject 호출됨: $projectId");

    // 🔥 먼저 labels 서브컬렉션 삭제
    final labelsSnapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    for (final labelDoc in labelsSnapshot.docs) {
      await labelDoc.reference.delete();
    }

    // 📦 프로젝트 문서 삭제
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId);
    await docRef.delete();

    debugPrint("[CloudStorageHelper] ✅ deleteSingleProject 완료: $projectId");
  }

  /// 📌 [saveLabelData]
  /// 특정 프로젝트 내 특정 데이터에 대한 라벨 데이터를 Firestore에 저장합니다.
  /// - 호출 위치: 사용자가 라벨링 후 저장 버튼 누를 때마다 호출됨
  /// - 저장 위치: users/{uid}/projects/{projectId}/labels/{dataId}
  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    debugPrint("[CloudStorageHelper] 💾 saveLabelData 호출됨: $projectId / $dataId");
    final labelRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').doc(dataId);
    debugPrint(
        "dataId, dataPath, mode, labeled_at, label_data: $dataId, $dataPath, ${labelModel.mode.toString()}, ${labelModel.labeledAt.toIso8601String()}, ${LabelModelConverter.toJson(labelModel)}");
    await labelRef.set({
      'data_id': dataId,
      'data_path': dataPath,
      'mode': labelModel.mode.toString(),
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'label_data': LabelModelConverter.toJson(labelModel),
    });
    debugPrint("[CloudStorageHelper] ✅ saveLabelData 완료: $projectId / $dataId");
  }

  /// 📌 [loadLabelData]
  /// 특정 데이터에 저장된 라벨을 Firestore에서 불러옵니다.
  /// - 호출 위치: 데이터 화면 진입 시마다 해당 데이터의 라벨 불러오기
  /// - 없으면 초기 라벨을 생성하여 반환
  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    debugPrint("[CloudStorageHelper] 📥 loadLabelData 호출됨: $projectId / $dataId");
    if (dataId.trim().isEmpty) {
      throw ArgumentError("❌ dataId가 비어 있어 라벨 문서를 참조할 수 없습니다.");
    }

    final labelRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').doc(dataId);
    final doc = await labelRef.get();
    if (!doc.exists) {
      debugPrint("[CloudStorageHelper] ⚠️ 라벨 없음 → 초기 라벨 생성");
      return LabelModelFactory.createNew(mode, dataId: dataId);
    }
    debugPrint("[CloudStorageHelper] ✅ 라벨 로드 완료: $dataId");
    return LabelModelConverter.fromJson(mode, doc.data()!['label_data']);
  }

  /// 📌 [saveAllLabels]
  /// 전체 라벨 리스트를 일괄 저장합니다 (Batch 사용).
  /// - 호출 위치: 전체 라벨 다운로드 전에 백업 목적 또는 일괄 저장 시
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    debugPrint("[CloudStorageHelper] 💾 saveAllLabels 호출됨: 총 ${labels.length}개");
    final batch = firestore.batch();
    final labelsRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels');

    for (var label in labels) {
      final docRef = labelsRef.doc(label.dataId);
      batch.set(docRef, {
        'mode': label.mode.toString(),
        'labeled_at': label.labeledAt.toIso8601String(),
        'label_data': LabelModelConverter.toJson(label),
      });
    }

    await batch.commit();
    debugPrint("[CloudStorageHelper] ✅ saveAllLabels 완료");
  }

  /// 📌 [loadAllLabelModels]
  /// 프로젝트에 저장된 모든 라벨을 불러옵니다.
  /// - 호출 위치: LabelingViewModel 생성 시 데이터 파일이 없을 경우 라벨 기반 복원
  /// - 내부적으로 LabelingMode 파싱하여 라벨 생성
  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    debugPrint("[CloudStorageHelper] 📥 loadAllLabelModels 호출됨: $projectId");
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    final labels = snapshot.docs.map((doc) {
      final data = doc.data();
      final rawMode = data['mode'];
      final mode = LabelingMode.values.firstWhere((e) => e.toString() == rawMode, orElse: () => throw StateError('Invalid labeling mode: $rawMode'));
      return LabelModelConverter.fromJson(mode, data['label_data']);
    }).toList();
    debugPrint("[CloudStorageHelper] ✅ loadAllLabelModels 완료: ${labels.length}개 라벨");
    return labels;
  }

  /// 📌 [deleteProjectLabels]
  /// 프로젝트에 연결된 모든 라벨 문서를 삭제합니다.
  /// - 호출 위치: 프로젝트 삭제 시 또는 라벨 초기화 시 사용
  @override
  Future<void> deleteProjectLabels(String projectId) async {
    debugPrint("[CloudStorageHelper] ❌ deleteProjectLabels 호출됨: $projectId");
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint("[CloudStorageHelper] ✅ deleteProjectLabels 완료: $projectId");
  }

  /// 📌 [deleteProject]
  /// 프로젝트 전체를 삭제합니다.
  /// - 내부적으로 `deleteProjectLabels()`를 호출하여 라벨을 먼저 삭제한 뒤,
  ///   프로젝트 문서 자체를 Firestore에서 제거합니다.
  @override
  Future<void> deleteProject(String projectId) async {
    debugPrint("[CloudStorageHelper] ❌ deleteProject 호출됨: $projectId");

    // 1️⃣ 라벨 데이터 삭제 (재사용)
    await deleteProjectLabels(projectId);

    // 2️⃣ 프로젝트 문서 삭제
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId);
    await docRef.delete();

    debugPrint("[CloudStorageHelper] ✅ deleteProject 완료: $projectId");
  }

  /// 📌 [downloadProjectConfig]
  @override
  Future<String> downloadProjectConfig(Project project) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(project.toJson(includeLabels: true));

    if (kIsWeb) {
      final blob = html.Blob([jsonString]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', '${project.name}_config.json')
        ..click();

      html.Url.revokeObjectUrl(url);
      return "${project.name}_config.json (downloaded in browser)";
    }

    // 🚫 Native에서는 지원하지 않음
    throw UnimplementedError("downloadProjectConfig()는 Web 플랫폼에서만 지원됩니다.");
  }

  /// 📌 [saveProjectConfig]
  /// 프로젝트 설정 정보를 Firebase에 저장합니다. `saveProjectList`와 기능적으로 동일
  /// - 비회원 모드에서 localStorage에 저장하던 것을 Firebase 방식으로 전환
  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    debugPrint("[CloudStorageHelper] 💾 saveProjectConfig 호출됨: ${projects.length}개 프로젝트");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');

    final batch = firestore.batch();
    final projectsRef = firestore.collection('users').doc(uid).collection('projects');

    for (var project in projects) {
      final docRef = projectsRef.doc(project.id);
      final json = project.toJson(includeLabels: false);

      json['dataInfos'] = project.dataInfos.map((e) => e.toJson()).toList();

      batch.set(docRef, json);
    }

    await batch.commit();
    debugPrint("[CloudStorageHelper] ✅ saveProjectConfig 완료");
  }

  /// 📌 [loadProjectFromConfig]
  /// local json 파일로부터 프로젝트 복원 (Firebase에서는 미사용)
  @override
  Future<List<Project>> loadProjectFromConfig(String config) async => throw UnimplementedError();

  /// 📌 [exportAllLabels]
  /// 라벨 데이터를 다운로드 가능한 파일로 내보냅니다 (Firebase에서는 미지원)
  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async => throw UnimplementedError();

  /// 📌 [importAllLabels]
  /// 외부 JSON 또는 ZIP로부터 라벨 데이터 임포트 (Firebase에서는 미지원)
  @override
  Future<List<LabelModel>> importAllLabels() async => throw UnimplementedError();

  /// 📌 [clearAllCache]
  /// Firebase에서는 사용되지 않으며, local storage에서만 의미 있음
  @override
  Future<void> clearAllCache() async => throw UnimplementedError();
}
