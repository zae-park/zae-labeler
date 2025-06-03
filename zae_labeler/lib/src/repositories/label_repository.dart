// lib/src/repositories/label_repository.dart

import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

/// ✅ LabelRepository
/// - 라벨 데이터를 저장/로드/삭제/내보내기/불러오기 담당
class LabelRepository {
  final StorageHelperInterface storageHelper;

  LabelRepository({required this.storageHelper});

  /// 📌 단일 라벨 저장
  /// - 특정 프로젝트의 특정 데이터에 대한 라벨 저장
  Future<void> saveLabel({required String projectId, required String dataId, required String dataPath, required LabelModel labelModel}) async {
    await storageHelper.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  /// 📌 단일 라벨 로드
  /// - 저장된 라벨이 없으면 초기화된 라벨 반환
  Future<LabelModel> loadLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    return await storageHelper.loadLabelData(projectId, dataId, dataPath, mode);
  }

  /// 📌 전체 라벨 일괄 저장
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    await storageHelper.saveAllLabels(projectId, labels);
  }

  /// 📌 전체 라벨 일괄 로드
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    return await storageHelper.loadAllLabelModels(projectId);
  }

  /// 📌 전체 라벨 삭제
  Future<void> deleteAllLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  /// 📌 라벨만 내보내기 (파일로 저장)
  /// - LabelModel만 export하고 Data는 포함하지 않음
  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    return await storageHelper.exportAllLabels(project, labels, []);
  }

  /// 📌 라벨 불러오기 (외부에서 import)
  /// - JSON 혹은 ZIP 등 외부 소스에서 불러옴
  Future<List<LabelModel>> importLabels() async {
    return await storageHelper.importAllLabels();
  }
}
