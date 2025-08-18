// lib/src/features/label/repository/label_repository.dart
import '../../../core/models/data/data_info.dart';
import '../../../core/models/project/project_model.dart';
import '../../label/models/label_model.dart';
import '../../../platform_helpers/storage/interface_storage_helper.dart';
// (임시) 검증 로직은 향후 UseCase/Service로 이전 예정
import 'package:zae_labeler/src/utils/label_validator.dart';

/// {@template label_repository}
/// ✅ LabelRepository
///
/// 라벨 데이터의 **영속화(IO)만** 담당하는 얇은 저장소 레이어입니다.
/// - 단건/일괄 저장·조회·삭제 및 Import/Export를 **StorageHelperInterface**에 위임합니다.
/// - 🔕 유효성 검사/상태 통계 등 도메인 규칙은 **UseCase/Service 레이어**로 이전하는 것을 권장합니다.
/// {@endtemplate}
class LabelRepository {
  final StorageHelperInterface storageHelper;

  LabelRepository({required this.storageHelper});

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 단일 라벨 처리 (CRUD)
  // ─────────────────────────────────────────────────────────────────────────────

  /// 단일 라벨 저장/갱신.
  /// - StorageHelper 구현체가 플랫폼별 직렬화/스키마 처리를 담당합니다.
  Future<void> saveLabel({required String projectId, required String dataId, required String dataPath, required LabelModel labelModel}) async {
    await storageHelper.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  /// 단일 라벨 로드.
  /// - 존재하지 않으면 StorageHelper 구현체가 초기 라벨을 반환하도록 설계되어 있습니다.
  Future<LabelModel> loadLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    return await storageHelper.loadLabelData(projectId, dataId, dataPath, mode);
  }

  /// 단일 라벨 로드(미존재 시 생성 보장).
  /// - 일부 구현체에서 예외가 날 가능성에 대비한 안전 래퍼.
  Future<LabelModel> loadOrCreateLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    try {
      return await loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    } catch (_) {
      return LabelModelFactory.createNew(mode, dataId: dataId);
    }
  }

  /// (임시) 특정 dataId의 라벨만 제거.
  /// - 단건 삭제 API가 StorageHelper에 없다면, 전체 로드→필터→일괄 저장으로 우회합니다.
  /// - TODO: 필요 시 `StorageHelperInterface.deleteLabel(projectId, dataId)` 추가 검토.
  Future<void> deleteLabelByDataId({required String projectId, required String dataId}) async {
    final all = await loadAllLabels(projectId);
    final filtered = all.where((e) => e.dataId != dataId).toList();
    await saveAllLabels(projectId, filtered);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 일괄 처리
  // ─────────────────────────────────────────────────────────────────────────────

  /// 프로젝트의 모든 라벨을 로드합니다.
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    return await storageHelper.loadAllLabelModels(projectId);
  }

  /// dataId → LabelModel 매핑으로 변환해 반환합니다.
  Future<Map<String, LabelModel>> loadLabelMap(String projectId) async {
    final labels = await loadAllLabels(projectId);
    return {for (final m in labels) m.dataId: m};
  }

  /// 라벨들을 일괄 저장합니다.
  /// - Firestore 등은 내부에서 배치/청크 처리(구현체 책임).
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    await storageHelper.saveAllLabels(projectId, labels);
  }

  /// 프로젝트의 모든 라벨을 삭제합니다.
  Future<void> deleteAllLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 Import / Export
  // ─────────────────────────────────────────────────────────────────────────────

  /// 라벨만 내보내기(원본 데이터 제외).
  /// - Web: 다운로드 트리거 / Cloud: Storage 업로드 등은 구현체가 처리.
  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    return await storageHelper.exportAllLabels(project, labels, const []);
  }

  /// 라벨 + 원본 데이터(가능한 범위) 내보내기.
  /// - Web(Native base64/path)에서만 일부 동작, Cloud는 보통 라벨만 스냅샷.
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) async {
    return await storageHelper.exportAllLabels(project, labels, dataInfos);
  }

  /// 라벨 임포트.
  /// - Web: 파일 선택 / Cloud: latest.json 로드 등은 구현체가 처리.
  Future<List<LabelModel>> importLabels() async {
    return await storageHelper.importAllLabels();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📌 유효성 검사 / 상태 (→ UseCase/Service로 이전 예정)
  // ─────────────────────────────────────────────────────────────────────────────

  /// 🔕 Repo 책임이 아님: UseCase/Service로 이전 권장.
  @Deprecated('Use LabelValidationUseCase/Service 레이어에서 처리하세요.')
  bool isValid(Project project, LabelModel labelModel) {
    return LabelValidator.isValid(labelModel, project);
  }

  /// 🔕 Repo 책임이 아님: UseCase/Service로 이전 권장.
  @Deprecated('Use LabelValidationUseCase/Service 레이어에서 처리하세요.')
  LabelStatus getStatus(Project project, LabelModel? labelModel) {
    return LabelValidator.getStatus(project, labelModel);
  }

  /// 🔕 Repo 책임이 아님: UseCase/Service로 이전 권장.
  @Deprecated('Use LabelValidationUseCase/Service 레이어에서 처리하세요.')
  bool isLabeled(LabelModel labelModel) {
    return labelModel.isLabeled;
  }
}
