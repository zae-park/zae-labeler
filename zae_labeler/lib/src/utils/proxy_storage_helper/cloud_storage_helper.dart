// lib/src/utils/cloud_storage_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../proxy_storage_helper/interface_storage_helper.dart';

class CloudStorageHelper implements StorageHelperInterface {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get _uid {
    final user = auth.currentUser;
    if (user == null) throw Exception("⚠️ 로그인된 사용자가 없습니다.");
    return user.uid;
  }

  // 📌 프로젝트 리스트 저장
  @override
  Future<void> saveProjectList(List<Project> projects) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'not-authenticated', message: '로그인이 필요합니다.');

    final uid = user.uid;
    final batch = firestore.batch();
    final projectsRef = firestore.collection('users').doc(uid).collection('projects');

    for (var project in projects) {
      final docRef = projectsRef.doc(project.id);
      batch.set(docRef, project.toJson(includeLabels: false));
    }

    await batch.commit();
  }

  // 📌 프로젝트 리스트 불러오기
  @override
  Future<List<Project>> loadProjectList() async {
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').get();
    return snapshot.docs.map((doc) => Project.fromJson(doc.data())).toList();
  }

  Future<void> saveSingleProject(Project project) async {
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(project.id);
    await docRef.set(project.toJson(includeLabels: false), SetOptions(merge: true));
  }

  Future<void> deleteSingleProject(String projectId) async {
    final docRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId);
    await docRef.delete();
  }

  // 📌 라벨 저장
  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    final labelRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').doc(dataId);

    await labelRef.set({
      'data_id': dataId,
      'data_path': dataPath,
      'mode': labelModel.runtimeType.toString(),
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'label_data': LabelModelConverter.toJson(labelModel),
    });
  }

  // 📌 라벨 불러오기
  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    final labelRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').doc(dataId);

    final doc = await labelRef.get();
    if (!doc.exists) return LabelModelFactory.createNew(mode);

    return LabelModelConverter.fromJson(mode, doc.data()!['label_data']);
  }

  // 📌 전체 라벨 저장
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final batch = firestore.batch();
    final labelsRef = firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels');

    for (var label in labels) {
      final docRef = labelsRef.doc(); // 또는 dataId 지정
      batch.set(docRef, {
        'mode': label.runtimeType.toString(),
        'labeled_at': label.labeledAt.toIso8601String(),
        'label_data': LabelModelConverter.toJson(label),
      });
    }

    await batch.commit();
  }

  // 📌 전체 라벨 불러오기
  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final mode = LabelingMode.values.firstWhere((e) => e.toString() == data['mode']);
      return LabelModelConverter.fromJson(mode, data['label_data']);
    }).toList();
  }

  // 📌 삭제
  @override
  Future<void> deleteProjectLabels(String projectId) async {
    final snapshot = await firestore.collection('users').doc(_uid).collection('projects').doc(projectId).collection('labels').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // 📌 config 임포트/익스포트 관련 기능은 Firebase에는 불필요 (local 다운로드용)
  @override
  Future<String> downloadProjectConfig(Project project) async => throw UnimplementedError();
  @override
  Future<void> saveProjectConfig(List<Project> projects) async => throw UnimplementedError();
  @override
  Future<List<Project>> loadProjectFromConfig(String config) async => throw UnimplementedError();

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList) async => throw UnimplementedError();

  @override
  Future<List<LabelModel>> importAllLabels() async => throw UnimplementedError();

  @override
  Future<void> clearAllCache() async => throw UnimplementedError();
}
