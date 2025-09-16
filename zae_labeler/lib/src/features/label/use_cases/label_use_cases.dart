// lib/src/features/label/use_cases/label_use_cases.dart
import '../../../core/models/project/project_model.dart';
import '../../../core/models/label/label_model.dart' show LabelModel, LabelingMode, LabelStatus;
import '../../label/repository/label_repository.dart';
import '../../project/repository/project_repository.dart';
import 'package:zae_labeler/src/utils/label_validator.dart';
import 'package:zae_labeler/src/platform_helpers/storage/switchable_storage_helper.dart'; // withCloud 사용

/// ---------------------------------------------------------------------------
/// 📊 라벨링 요약 DTO
/// ---------------------------------------------------------------------------
class LabelingSummary {
  final int total; // 전체 데이터 개수 (= project.dataInfos.length)
  final int complete; // 완료 상태 개수
  final int warning; // 경고 상태 개수(불완전/의심 등)
  final int incomplete; // 미완료 개수 (= total - complete)
  final double progress; // 진행률(0.0~1.0) = complete / total

  const LabelingSummary({required this.total, required this.complete, required this.warning, required this.incomplete, required this.progress});

  LabelingSummary.empty() : total = 0, complete = 0, warning = 0, incomplete = 0, progress = 0.0;

  @override
  String toString() =>
      'LabelingSummary(total=$total, complete=$complete, warning=$warning, incomplete=$incomplete, progress=${(progress * 100).toStringAsFixed(1)}%)';
}

/// ---------------------------------------------------------------------------
/// ✅ LabelUseCases (최종 파사드)
/// ---------------------------------------------------------------------------
/// 라벨 관련 시나리오를 한 곳에서 오케스트레이션합니다.
///
/// - 단일/일괄 저장·조회는 LabelRepository에 위임
/// - Import/Export는 필요 시 Project 컨텍스트를 같이 사용
/// - 검증/상태 및 요약 계산은 여기서 수행 (Repo는 IO만 담당)
///
/// 구버전 매핑:
///  - SingleLabelUseCase.load/save/delete → loadOrCreate / save / deleteByDataId
///  - BatchLabelUseCase.loadAll/saveAll/clear → loadAll / saveAll / clearAll
///  - LabelIoUseCase.export/import → exportProjectLabels / importLabelsAndSaveAll
///  - ValidateLabelUseCase.isValid/status → isValid / statusOf
///  - LabelingSummaryUseCase.summary → computeSummary / computeSummaryFor
class LabelUseCases {
  final LabelRepository labelRepo;
  final ProjectRepository projectRepo;

  const LabelUseCases({required this.labelRepo, required this.projectRepo});

  /// 부트스트랩 편의 생성자
  factory LabelUseCases.from(LabelRepository labelRepo, ProjectRepository projectRepo) {
    return LabelUseCases(labelRepo: labelRepo, projectRepo: projectRepo);
  }

  // ===========================================================================
  // 📌 단일 CRUD
  // ===========================================================================

  /// 단일 라벨 로드(없으면 생성하여 반환).
  /// - [dataPath]는 Native에선 파일 경로, Web/Cloud에서는 보통 빈 문자열/nullable
  Future<LabelModel> loadOrCreate({required String projectId, required String dataId, String dataPath = '', required LabelingMode mode}) {
    return labelRepo.loadOrCreateLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    // 참고: storageHelper는 표준 래퍼 {data_id, data_path, mode(name), labeled_at, label_data}를 사용해야 일관됩니다.
  }

  /// 단일 라벨 저장/갱신.
  Future<void> save({required String projectId, required String dataId, String dataPath = '', required LabelModel model}) {
    return labelRepo.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: model);
  }

  /// 단일 라벨 삭제.
  /// - StorageHelper에 단건 삭제 API가 없으므로 전체 로드→필터→재저장 방식으로 위임 처리.
  Future<void> deleteByDataId({required String projectId, required String dataId}) {
    return labelRepo.deleteLabelByDataId(projectId: projectId, dataId: dataId);
  }

  // ===========================================================================
  // 📌 일괄 처리
  // ===========================================================================

  /// 프로젝트의 모든 라벨 로드.
  Future<List<LabelModel>> loadAll(String projectId) {
    return labelRepo.loadAllLabels(projectId);
  }

  /// dataId → LabelModel 매핑으로 반환.
  Future<Map<String, LabelModel>> loadMap(String projectId) {
    return labelRepo.loadLabelMap(projectId);
  }

  /// 라벨 일괄 저장.
  Future<void> saveAll(String projectId, List<LabelModel> labels) {
    return labelRepo.saveAllLabels(projectId, labels);
  }

  /// 전체 라벨 삭제.
  Future<void> clearAll(String projectId) {
    return labelRepo.deleteAllLabels(projectId);
  }

  // ===========================================================================
  // 📌 Import / Export
  // ===========================================================================

  /// 현재 프로젝트의 라벨을 내보냅니다.
  /// - [withData] = true 이면 가능한 범위에서 원본 데이터 포함(Web base64 / Native 파일)
  /// - Cloud는 일반적으로 labels.json 스냅샷 업로드(파일 동반 X)
  Future<String> exportProjectLabels(String projectId, {bool withData = false}) async {
    final project = await projectRepo.findById(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }
    final labels = await labelRepo.loadAllLabels(projectId);
    if (withData) {
      return labelRepo.exportLabelsWithData(project, labels, project.dataInfos);
    }
    return labelRepo.exportLabels(project, labels);
  }

  /// 라벨을 임포트하여 프로젝트에 저장하고, 저장된 개수를 반환합니다.
  /// - Web: 파일 선택 → 파싱 후 저장
  /// - Cloud: latest.json 다운로드 → 파싱 후 저장
  Future<int> importLabelsAndSaveAll(String projectId) async {
    final imported = await labelRepo.importLabels();
    if (imported.isEmpty) return 0;
    await labelRepo.saveAllLabels(projectId, imported);
    return imported.length;
  }

  // ===========================================================================
  // 📌 검증 / 상태
  // ===========================================================================

  /// 단일 라벨 유효성 검사.
  bool isValid(Project project, LabelModel label) {
    return LabelValidator.isValid(label, project);
  }

  /// 단일 라벨 상태 계산.
  LabelStatus statusOf(Project project, LabelModel? label) {
    return LabelValidator.getStatus(project, label);
  }

  // ===========================================================================
  // 📌 요약 / 통계
  // ===========================================================================

  /// 프로젝트 ID 기준 전체 라벨링 진행 요약(스토리지 조회 포함).
  Future<LabelingSummary> computeSummary(String projectId) async {
    final project = await projectRepo.findById(projectId);
    if (project == null) {
      return const LabelingSummary(total: 0, complete: 0, warning: 0, incomplete: 0, progress: 0.0);
    }
    final labels = await labelRepo.loadAllLabels(projectId);
    return computeSummaryFor(project, labels);
  }

  Future<LabelingSummary> computeSummaryCloudFirst(String projectId) async {
    final project = await projectRepo.findById(projectId);
    if (project == null) {
      return LabelingSummary.empty();
    }
    final storage = labelRepo.storageHelper; // LabelRepository에 getter 필요
    if (storage is SwitchableStorageHelper) {
      try {
        final models = await storage.withCloud((cloud) => cloud.loadAllLabelModels(projectId));
        return computeSummaryFor(project, models);
      } catch (_) {
        final local = await labelRepo.loadAllLabels(projectId);
        return computeSummaryFor(project, local);
      }
    }
    return computeSummary(projectId);
  }

  /// (편의) 프로젝트 객체로 직접 요약 계산(라벨은 내부 조회).
  Future<LabelingSummary> computeSummaryByProject(Project project) async {
    final labels = await labelRepo.loadAllLabels(project.id);
    return computeSummaryFor(project, labels);
  }

  /// 주어진 프로젝트/라벨 컬렉션을 기반으로 진행 요약 계산.
  /// - 경고는 완료와 별도 집계(불완전/의심치가 있는 경우)
  /// - 미완료 = total - complete
  LabelingSummary computeSummaryFor(Project project, List<LabelModel> labels) {
    final total = project.dataInfos.length;
    int complete = 0, warning = 0;

    final labelMap = {for (final m in labels) m.dataId: m};
    for (final info in project.dataInfos) {
      final lbl = labelMap[info.id];
      final status = LabelValidator.getStatus(project, lbl);
      if (status == LabelStatus.complete) complete++;
      if (status == LabelStatus.warning) warning++;
    }

    final incomplete = (total - complete).clamp(0, total);
    final progress = total == 0 ? 0.0 : complete / total;
    return LabelingSummary(total: total, complete: complete, warning: warning, incomplete: incomplete, progress: progress);
  }

  /// (편의) 상태 맵 계산: dataId → LabelStatus
  Map<String, LabelStatus> statusMapFor(Project project, List<LabelModel> labels) {
    final map = <String, LabelStatus>{};
    final labelMap = {for (final m in labels) m.dataId: m};
    for (final info in project.dataInfos) {
      map[info.id] = LabelValidator.getStatus(project, labelMap[info.id]);
    }
    return map;
  }
}
