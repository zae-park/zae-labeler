// lib/src/utils/cloud_storage_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../proxy_storage_helper/interface_storage_helper.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');

    final uid = user.uid;
    final batch = firestore.batch();
    final projectsRef = firestore.collection('users').doc(uid).collection('projects');

    for (var project in projects) {
      final docRef = projectsRef.doc(project.id);

      final json = project.toJson(includeLabels: false);

      // ✅ Web에서는 dataPaths 제거 또는 비어 있으면 제거
      if (kIsWeb) {
        json.remove('dataPaths');
      } else {
        json['dataPaths'] = project.dataPaths.map((e) => e.toJson()).toList();
      }

      batch.set(docRef, json);
    }

    await batch.commit();
  }

  /// 📌 [loadProjectList]
  /// 현재 로그인된 사용자의 모든 프로젝트 리스트를 Firestore에서 로드합니다.
  /// - 호출 위치: 앱 초기 로딩 시 프로젝트 리스트 조회용
  @override
  Future<List<Project>> loadProjectList() async {
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').get();
    return snapshot.docs.map((doc) => Project.fromJson(doc.data())).toList();
  }

  /// 📌 [saveSingleProject]
  /// 단일 프로젝트를 Firestore에 저장합니다 (병합 저장).
  /// - 호출 위치: 프로젝트 수정 시 단건 업데이트
  Future<void> saveSingleProject(Project project) async {
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(project.id);
    final json = project.toJson(includeLabels: true);

    if (kIsWeb) {
      json.remove('dataPaths');
    } else {
      json['dataPaths'] = project.dataPaths.map((e) => e.toJson()).toList();
    }

    await docRef.set(json, SetOptions(merge: true));
  }

  /// 📌 [deleteSingleProject]
  /// Firestore에서 특정 프로젝트 문서를 삭제합니다.
  /// - 호출 위치: 프로젝트 삭제 시
  Future<void> deleteSingleProject(String projectId) async {
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId);
    await docRef.delete();
  }

  /// 📌 [saveLabelData]
  /// 특정 프로젝트 내 특정 데이터에 대한 라벨 데이터를 Firestore에 저장합니다.
  /// - 호출 위치: 사용자가 라벨링 후 저장 버튼 누를 때마다 호출됨
  /// - 저장 위치: users/{uid}/projects/{projectId}/labels/{dataId}
  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
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
  }

  /// 📌 [loadLabelData]
  /// 특정 데이터에 저장된 라벨을 Firestore에서 불러옵니다.
  /// - 호출 위치: 데이터 화면 진입 시마다 해당 데이터의 라벨 불러오기
  /// - 없으면 초기 라벨을 생성하여 반환
  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    final labelRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').doc(dataId);

    final doc = await labelRef.get();
    if (!doc.exists) return LabelModelFactory.createNew(mode);

    return LabelModelConverter.fromJson(mode, doc.data()!['label_data']);
  }

  /// 📌 [saveAllLabels]
  /// 전체 라벨 리스트를 일괄 저장합니다 (Batch 사용).
  /// - 호출 위치: 전체 라벨 다운로드 전에 백업 목적 또는 일괄 저장 시
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final batch = firestore.batch();
    final labelsRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels');

    for (var label in labels) {
      final docRef = labelsRef.doc(label.dataId); // 또는 dataId 지정
      batch.set(docRef, {
        'mode': label.mode.toString(),
        'labeled_at': label.labeledAt.toIso8601String(),
        'label_data': LabelModelConverter.toJson(label),
      });
    }

    await batch.commit();
  }

  /// 📌 [loadAllLabelModels]
  /// 프로젝트에 저장된 모든 라벨을 불러옵니다.
  /// - 호출 위치: LabelingViewModel 생성 시 데이터 파일이 없을 경우 라벨 기반 복원
  /// - 내부적으로 LabelingMode 파싱하여 라벨 생성
  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final rawMode = data['mode'];
      final mode = LabelingMode.values.firstWhere((e) => e.toString() == rawMode, orElse: () => throw StateError('Invalid labeling mode: $rawMode'));
      return LabelModelConverter.fromJson(mode, data['label_data']);
    }).toList();
  }

  /// 📌 [deleteProjectLabels]
  /// 프로젝트에 연결된 모든 라벨 문서를 삭제합니다.
  /// - 호출 위치: 프로젝트 삭제 시 또는 라벨 초기화 시 사용
  @override
  Future<void> deleteProjectLabels(String projectId) async {
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// 📌 [downloadProjectConfig]
  /// Firebase 환경에서는 사용되지 않음. localStorage 전용 메소드
  @override
  Future<String> downloadProjectConfig(Project project) async => throw UnimplementedError();

  /// 📌 [saveProjectConfig]
  /// 프로젝트 설정 정보를 Firebase에 저장합니다. `saveProjectList`와 기능적으로 동일
  /// - 비회원 모드에서 localStorage에 저장하던 것을 Firebase 방식으로 전환
  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');

    final batch = firestore.batch();
    final projectsRef = firestore.collection('users').doc(uid).collection('projects');

    for (var project in projects) {
      final docRef = projectsRef.doc(project.id);

      final json = project.toJson(includeLabels: false);

      if (kIsWeb) {
        json.remove('dataPaths');
      } else {
        json['dataPaths'] = project.dataPaths.map((e) => e.toJson()).toList();
      }

      batch.set(docRef, json);
    }

    await batch.commit();
  }

  /// 📌 [loadProjectFromConfig]
  /// local json 파일로부터 프로젝트 복원 (Firebase에서는 미사용)
  @override
  Future<List<Project>> loadProjectFromConfig(String config) async => throw UnimplementedError();

  /// 📌 [exportAllLabels]
  /// 라벨 데이터를 다운로드 가능한 파일로 내보냅니다 (Firebase에서는 미지원)
  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList) async => throw UnimplementedError();

  /// 📌 [importAllLabels]
  /// 외부 JSON 또는 ZIP로부터 라벨 데이터 임포트 (Firebase에서는 미지원)
  @override
  Future<List<LabelModel>> importAllLabels() async => throw UnimplementedError();

  /// 📌 [clearAllCache]
  /// Firebase에서는 사용되지 않으며, local storage에서만 의미 있음
  @override
  Future<void> clearAllCache() async => throw UnimplementedError();
}
