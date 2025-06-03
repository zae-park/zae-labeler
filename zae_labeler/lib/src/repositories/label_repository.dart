// lib/src/repositories/label_repository.dart

import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';
import 'package:zae_labeler/src/utils/label_validator.dart';

/// {@template label_repository}
/// ✅ LabelRepository
///
/// 라벨 데이터를 중앙에서 관리하는 저장소 역할로,
/// 저장, 로드, 초기화, 일괄 처리, 유효성 검사 및 내보내기 기능을 제공합니다.
///
/// - StorageHelper를 래핑하여 뷰모델이 간결한 인터페이스로 라벨을 다룰 수 있게 합니다.
/// - 라벨 유효성 검사 로직도 포함합니다.
/// {@endtemplate}
class LabelRepository {
  final StorageHelperInterface storageHelper;

  LabelRepository({required this.storageHelper});

  /// 📌 단일 라벨 저장
  Future<void> saveLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelModel labelModel,
  }) async {
    await storageHelper.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  /// 📌 단일 라벨 로드
  Future<LabelModel> loadLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelingMode mode,
  }) async {
    return await storageHelper.loadLabelData(projectId, dataId, dataPath, mode);
  }

  /// 📌 라벨 로드 or 생성
  ///
  /// - 저장된 라벨이 없으면 기본 라벨 생성
  Future<LabelModel> loadOrCreateLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelingMode mode,
  }) async {
    try {
      return await loadLabel(
        projectId: projectId,
        dataId: dataId,
        dataPath: dataPath,
        mode: mode,
      );
    } catch (_) {
      return LabelModelFactory.createNew(mode, dataId: dataId);
    }
  }

  /// 📌 모든 라벨 로드 (리스트 반환)
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    return await storageHelper.loadAllLabelModels(projectId);
  }

  /// 📌 모든 라벨 로드 (Map 반환)
  ///
  /// - dataId → LabelModel 매핑
  Future<Map<String, LabelModel>> loadLabelMap(String projectId) async {
    final labels = await loadAllLabels(projectId);
    return {for (var label in labels) label.dataId: label};
  }

  /// 📌 모든 라벨 저장
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    await storageHelper.saveAllLabels(projectId, labels);
  }

  /// 📌 프로젝트의 모든 라벨 삭제
  Future<void> deleteAllLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  /// 📌 외부로 라벨만 export (파일 저장)
  ///
  /// - Data는 포함하지 않음
  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    return await storageHelper.exportAllLabels(project, labels, []);
  }

  /// 📌 외부로 라벨 + 데이터 정보 함께 export
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) async {
    return await storageHelper.exportAllLabels(project, labels, dataInfos);
  }

  /// 📌 외부에서 라벨 import
  ///
  /// - JSON or ZIP
  Future<List<LabelModel>> importLabels() async {
    return await storageHelper.importAllLabels();
  }

  /// 📌 라벨이 유효한지 검사
  ///
  /// - 프로젝트의 클래스 기준으로 판단
  bool isValid(Project project, LabelModel labelModel) {
    return LabelValidator.isValid(labelModel, project);
  }

  /// 📌 라벨 상태를 반환 (완료/주의/미완료)
  LabelStatus getStatus(Project project, LabelModel? labelModel) {
    return LabelValidator.getStatus(project, labelModel);
  }

  /// 📌 해당 라벨이 완전히 작성되었는지 여부
  bool isLabeled(LabelModel labelModel) {
    return labelModel.isLabeled;
  }
}
