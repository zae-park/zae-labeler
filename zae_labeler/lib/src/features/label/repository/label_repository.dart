import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/get_storage_helper.dart';
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 단일 라벨 처리
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> saveLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelModel labelModel,
  }) async {
    await storageHelper.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  Future<LabelModel> loadLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelingMode mode,
  }) async {
    return await storageHelper.loadLabelData(projectId, dataId, dataPath, mode);
  }

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

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 일괄 처리
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    return await storageHelper.loadAllLabelModels(projectId);
  }

  Future<Map<String, LabelModel>> loadLabelMap(String projectId) async {
    final labels = await loadAllLabels(projectId);
    return {for (var label in labels) label.dataId: label};
  }

  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    await storageHelper.saveAllLabels(projectId, labels);
  }

  Future<void> deleteAllLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 Import / Export
  // ─────────────────────────────────────────────────────────────────────────────

  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    return await storageHelper.exportAllLabels(project, labels, []);
  }

  Future<String> exportLabelsWithData(
    Project project,
    List<LabelModel> labels,
    List<DataInfo> dataInfos,
  ) async {
    return await storageHelper.exportAllLabels(project, labels, dataInfos);
  }

  Future<List<LabelModel>> importLabels() async {
    return await storageHelper.importAllLabels();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 유효성 검사
  // ─────────────────────────────────────────────────────────────────────────────

  bool isValid(Project project, LabelModel labelModel) {
    return LabelValidator.isValid(labelModel, project);
  }

  LabelStatus getStatus(Project project, LabelModel? labelModel) {
    return LabelValidator.getStatus(project, labelModel);
  }

  bool isLabeled(LabelModel labelModel) {
    return labelModel.isLabeled;
  }
}
