// lib/src/features/project/use_cases/project_use_cases.dart
import '../../label/models/label_model.dart' show LabelingMode; // TODO: Mode 분리 후 제거
import '../../../core/models/data/data_info.dart';
import '../../../core/models/project/project_model.dart';
import '../../label/repository/label_repository.dart';
import '../../project/repository/project_repository.dart';

/// {@template project_use_cases}
/// ✅ ProjectUseCases (파사드)
///
/// 프로젝트 관련 시나리오를 한 곳에서 오케스트레이션합니다.
/// - 단순 CRUD/속성 변경 → ProjectRepository에 위임
/// - 라벨과의 교차 시나리오(모드 변경+라벨 초기화, 완전 삭제 등) → LabelRepository와 함께 수행
///
/// 팁: 부트스트랩에서 `from(projectRepo, labelRepo: ...)`로 전달하면
/// 라벨 초기화/완전삭제 같은 시나리오를 더욱 명시적으로 실행할 수 있습니다.
/// {@endtemplate}
class ProjectUseCases {
  final ProjectRepository projectRepo;
  final LabelRepository? labelRepo;

  const ProjectUseCases({required this.projectRepo, this.labelRepo});

  /// 부트스트랩 편의 생성자(기존 호환)
  factory ProjectUseCases.from(ProjectRepository repo, {LabelRepository? labelRepo}) {
    return ProjectUseCases(projectRepo: repo, labelRepo: labelRepo);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 조회
  // ────────────────────────────────────────────────────────────────────────────

  /// 전체 프로젝트 목록
  Future<List<Project>> fetchAll() => projectRepo.fetchAllProjects();

  /// ID로 단일 조회
  Future<Project?> findById(String id) => projectRepo.findById(id);

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 메타/속성
  // ────────────────────────────────────────────────────────────────────────────

  /// 이름 변경
  Future<Project?> rename(String projectId, String newName) => projectRepo.updateProjectName(projectId, newName);

  /// 클래스 목록 교체
  Future<Project?> updateClasses(String projectId, List<String> classes) => projectRepo.updateProjectClasses(projectId, classes);

  /// 라벨링 모드만 변경 (라벨 초기화는 수행하지 않음)
  Future<Project?> changeModeOnly(String projectId, LabelingMode newMode) => projectRepo.updateProjectMode(projectId, newMode);

  /// 라벨링 모드 변경 + 모든 라벨 초기화(권장 시나리오)
  /// - labelRepo가 주입되어 있지 않으면, 안전하게 모드만 변경합니다.
  Future<Project?> changeModeAndReset(String projectId, LabelingMode newMode) async {
    if (labelRepo != null) {
      await labelRepo!.deleteAllLabels(projectId);
    }
    return projectRepo.updateProjectMode(projectId, newMode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 DataInfo 관리
  // ────────────────────────────────────────────────────────────────────────────

  Future<Project?> replaceDataInfos(String projectId, List<DataInfo> infos) => projectRepo.updateDataInfos(projectId, infos);

  Future<Project?> addDataInfo(String projectId, DataInfo info) => projectRepo.addDataInfo(projectId, info);

  Future<Project?> removeDataInfo(String projectId, String dataInfoId) => projectRepo.removeDataInfoById(projectId, dataInfoId);

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 Project IO(Import/Export)
  // ────────────────────────────────────────────────────────────────────────────

  /// 외부 설정(JSON 등)에서 프로젝트들 가져오기
  Future<List<Project>> importFromExternal() => projectRepo.importFromExternal();

  /// 단일 프로젝트 구성 다운로드(웹 등)
  Future<String> exportConfig(Project project) => projectRepo.exportConfig(project);

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 라이프사이클
  // ────────────────────────────────────────────────────────────────────────────

  /// 프로젝트 완전 삭제
  /// - labelRepo가 있으면 모든 라벨을 명시적으로 삭제 후 프로젝트 삭제
  /// - 없어도 StorageHelper의 cascade에 의존해 프로젝트만 삭제
  Future<void> deleteProjectFully(String projectId) async {
    if (labelRepo != null) {
      await labelRepo!.deleteAllLabels(projectId);
    }
    await projectRepo.deleteById(projectId);
  }
}
