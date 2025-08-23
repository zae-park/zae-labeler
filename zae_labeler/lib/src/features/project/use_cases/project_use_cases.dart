// lib/src/features/project/use_cases/project_use_cases.dart
import 'package:zae_labeler/src/core/models/label/label_types.dart';

import '../../../core/models/data/data_info.dart';
import '../../../core/models/project/project_model.dart';
import '../../label/repository/label_repository.dart';
import '../../project/repository/project_repository.dart';
import '../../project/logic/project_validator.dart';
import 'edit_project_use_case.dart';

/// {@template project_use_cases}
/// ✅ ProjectUseCases (파사드)
///
/// 역할
/// - **조회/라이프사이클/IO**: ProjectRepository에 위임.
/// - **편집(이름/모드/클래스/데이터소스)**: EditProjectUseCase에 위임해 검증·저장을 일관 수행.
/// - **라벨 교차 시나리오**: LabelRepository가 있을 때만 안전하게 수행(예: 모드 변경 시 라벨 초기화).
///
/// 설계 포인트
/// - ID만 받은 호출자를 대신해 프로젝트를 로드하고, 편집 유스케이스에 **Project 인스턴스**를 넘깁니다.
/// - 편집 규칙과 검증은 EditProjectUseCase/ProjectValidator가 책임지며,
///   여기서는 **오케스트레이션과 중복 방지(머지)** 등 얇은 정책만 다룹니다.
/// {@endtemplate}
class ProjectUseCases {
  final ProjectRepository projectRepo;
  final LabelRepository? labelRepo;
  final EditProjectUseCase editor;

  const ProjectUseCases({required this.projectRepo, required this.editor, this.labelRepo});

  /// 부트스트랩 편의 생성자(기존 호환)
  factory ProjectUseCases.from(ProjectRepository repo, {required EditProjectUseCase editor, LabelRepository? labelRepo}) {
    return ProjectUseCases(projectRepo: repo, editor: editor, labelRepo: labelRepo);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 🔎 조회
  // ────────────────────────────────────────────────────────────────────────────

  /// 전체 프로젝트 목록
  Future<List<Project>> fetchAll() => projectRepo.fetchAllProjects();

  /// ID로 단일 조회
  Future<Project?> findById(String id) => projectRepo.findById(id);

  // 내부 헬퍼: 존재 보장 로드
  Future<Project> _require(String id) async {
    final p = await projectRepo.findById(id);
    if (p == null) {
      throw StateError('프로젝트를 찾을 수 없습니다: $id');
    }
    return p;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 🧩 메타/속성(편집은 가능하면 editor로 위임)
  // ────────────────────────────────────────────────────────────────────────────

  /// 이름 변경 (검증·저장 포함)
  Future<Project> rename(String projectId, String newName) async {
    final p = await _require(projectId);
    return editor.rename(p, newName);
  }

  /// 라벨링 모드만 변경(라벨엔 손대지 않음) — 저장 책임은 Repo.
  /// 편집 규칙을 강제하지 않아야 하는 특수 케이스를 위해 유지.
  Future<Project?> changeModeOnly(String projectId, LabelingMode newMode) {
    return projectRepo.updateProjectMode(projectId, newMode);
  }

  /// 라벨링 모드 변경 + 정책에 따른 라벨 처리(권장 경로)
  /// 기본 정책: 모든 라벨 삭제 후 모드 변경.
  Future<Project> changeModeAndReset(String projectId, LabelingMode newMode) async {
    final p = await _require(projectId);
    return editor.changeMode(p, newMode, policy: ModeChangePolicy.deleteAll);
  }

  /// 클래스 **전체 교체**.
  /// - editor에 set 전용 API가 없으므로, 여기서 1차 검증 후 Repo로 직접 반영.
  /// - 부분 편집(add/edit/remove)은 editor의 메서드를 사용하세요.
  Future<Project?> updateClasses(String projectId, List<String> classes) async {
    ProjectValidator.checkClasses(classes);
    return projectRepo.updateProjectClasses(projectId, classes);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📂 DataInfo 관리(가능하면 editor 위임 + 중복 방지 머지)
  // ────────────────────────────────────────────────────────────────────────────

  /// 전체 교체 (검증·저장 포함, editor 위임)
  Future<Project> replaceDataInfos(String projectId, List<DataInfo> infos) async {
    final p = await _require(projectId);
    return editor.setDataInfos(p, infos);
  }

  /// 단건 추가 — 동일 id가 있으면 덮어쓰기(머지) 후 저장.
  Future<Project> addDataInfo(String projectId, DataInfo info) async {
    final p = await _require(projectId);
    final map = {for (final d in p.dataInfos) d.id: d};
    map[info.id] = info;
    final merged = map.values.toList(growable: false);
    return editor.setDataInfos(p, merged);
  }

  /// ✅ 배치 추가 — 동일 id는 마지막 항목으로 덮어쓰며 병합.
  Future<Project> addDataInfos(String projectId, List<DataInfo> infos) async {
    final p = await _require(projectId);
    final map = {for (final d in p.dataInfos) d.id: d};
    for (final n in infos) {
      map[n.id] = n;
    }
    final merged = map.values.toList(growable: false);
    return editor.setDataInfos(p, merged);
  }

  /// 단건 제거 — id로 찾은 뒤 index 기반 editor 호출(검증·저장 포함)
  Future<Project> removeDataInfo(String projectId, String dataInfoId) async {
    final p = await _require(projectId);
    final index = p.dataInfos.indexWhere((e) => e.id == dataInfoId);
    if (index < 0) {
      // 없으면 그대로 반환(혹은 예외로 바꾸고 싶으면 throw StateError)
      return p;
    }
    return editor.removeDataInfo(p, index);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ⬆️⬇️ Project IO
  // ────────────────────────────────────────────────────────────────────────────

  /// 외부 설정(JSON 등)에서 프로젝트들 가져오기
  Future<List<Project>> importFromExternal() => projectRepo.importFromExternal();

  /// 단일 프로젝트 구성 다운로드(웹 등)
  Future<String> exportConfig(Project project) => projectRepo.exportConfig(project);

  // ────────────────────────────────────────────────────────────────────────────
  // 🔄 라이프사이클
  // ────────────────────────────────────────────────────────────────────────────

  /// 단일 프로젝트 저장(업서트)
  Future<void> save(Project project) => projectRepo.saveProject(project);

  /// 여러 프로젝트 일괄 저장
  Future<void> saveAll(List<Project> list) => projectRepo.saveAll(list);

  /// 단일 프로젝트 삭제(프로젝트 엔티티만)
  Future<void> deleteById(String projectId) => projectRepo.deleteById(projectId);

  /// 전체 삭제(프로젝트 엔티티만)
  Future<void> deleteAll() => projectRepo.deleteAll();

  /// 프로젝트 완전 삭제(라벨까지)
  /// - labelRepo가 있으면 명시적 라벨 삭제 후 프로젝트 삭제
  /// - 없으면 StorageHelper의 cascade에 위임
  Future<void> deleteProjectFully(String projectId) async {
    if (labelRepo != null) {
      await labelRepo!.deleteAllLabels(projectId);
    }
    await projectRepo.deleteById(projectId);
  }
}
