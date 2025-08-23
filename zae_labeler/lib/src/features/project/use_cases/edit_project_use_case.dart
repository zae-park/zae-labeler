import 'dart:async';

import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/features/project/logic/project_validator.dart';

import '../../../core/models/project/project_model.dart';

// 레포지토리 경로는 프로젝트 구조에 맞춰 조정하세요.
import '../../project/repository/project_repository.dart';
import '../../label/repository/label_repository.dart';

/// 모드 변경 시 기존 라벨을 어떻게 처리할지 선택하는 정책
enum ModeChangePolicy {
  /// 가장 안전한 기본값. 모드가 바뀌면 해당 프로젝트 라벨을 전부 삭제한다.
  deleteAll,

  /// (선택) 외부에서 마이그레이션 전략을 제공할 때 사용.
  /// 예) 단일 → 다중 분류 변환 등 호환 가능한 라벨만 변환.
  migrateWithStrategy,
}

/// {@template edit_project_use_case}
/// 프로젝트 편집(이름/모드/클래스/데이터)과 관련된 **비즈니스 규칙의 단일 관문(Use Case)**.
///
/// - VM은 이 유스케이스를 호출해 **새로운 Project 스냅샷**을 받아 교체하고 `notify`만 수행한다.
/// - 저장 직전/부분 편집 단계의 상세 검증은 [ProjectValidator]가 담당한다.
/// - 모드 변경 시 라벨 정리/마이그레이션을 [ModeChangePolicy]로 제어한다.
/// - 영속화는 [ProjectRepository]에 위임하며, 라벨 관련 일괄 처리는 [LabelRepository]에 위임한다.
/// {@endtemplate}
class EditProjectUseCase {
  final ProjectRepository _projects;
  final LabelRepository _labels;
  final ProjectValidator _validator;

  /// {@macro edit_project_use_case}
  ///
  /// - [projectRepository]: 프로젝트 영속화(저장/교체) 책임.
  /// - [labelRepository]: 라벨 정리/일괄 처리 책임.
  /// - [validator]: 필드 단위 및 전체 프로젝트 유효성 검증 책임.
  EditProjectUseCase({required ProjectRepository projectRepository, required LabelRepository labelRepository, required ProjectValidator validator})
      : _projects = projectRepository,
        _labels = labelRepository,
        _validator = validator;

  // ---------------------------
  // 공통 유틸
  // ---------------------------

  /// 내부 편의 함수: 저장 전 변경 이력을 남기거나 `updatedAt`을 갱신하는 용도.
  ///
  /// 현재는 단순히 [Project.copyWith]를 호출해 새 인스턴스를 만든다.
  /// 만약 `Project`에 `updatedAt` 필드가 없다면 이 호출은 사실상 no-op이다.
  Project _touch(Project p) => p.copyWith(); // updatedAt 필드가 없다면 제거

  /// 공통 저장 시퀀스.
  ///
  /// 1) [ProjectValidator.validate]로 전체 스냅샷 검증
  /// 2) [ProjectRepository.saveProject]로 영속화
  /// 3) 저장된 스냅샷을 그대로 반환
  Future<Project> _save(Project p) async {
    // 저장 전 전체 유효성 검증
    ProjectValidator.validate(p);
    await _projects.saveProject(p);
    return p;
  }

  // ---------------------------
  // 개별 편집 동작
  // ---------------------------

  /// 프로젝트 **이름 변경**.
  ///
  /// - [name]은 공백 불가 및 길이/형식 검증을 수행한다(자세한 규칙은 [ProjectValidator.checkProjectName]).
  /// - 성공 시 변경된 프로젝트 스냅샷을 저장하고 반환한다.
  Future<Project> rename(Project p, String name) async {
    ProjectValidator.checkProjectName(name);
    final np = _touch(p.copyWith(name: name));
    return _save(np);
  }

  /// 프로젝트 **라벨링 모드 변경**.
  ///
  /// - 동일 모드 입력 시 조기 종료한다.
  /// - 변경 전에 [_labels.hasAny]로 라벨 존재 여부를 조회, 사전 정책 검증은
  ///   [ProjectValidator.precheckModeChange]가 수행한다.
  /// - [policy]에 따라 기존 라벨을 **전부 삭제**하거나, 외부 [migrate] 전략으로 **마이그레이션**한다.
  /// - 최종적으로 모드가 교체된 프로젝트를 저장 후 반환한다.
  ///
  /// 예시:
  /// ```dart
  /// await useCase.changeMode(
  ///   project,
  ///   LabelingMode.multiClass,
  ///   policy: ModeChangePolicy.migrateWithStrategy,
  ///   migrate: ({required projectId, required from, required to, required labels}) async {
  ///     // from 단일 → to 다중 변환 전략 구현
  ///   },
  /// );
  /// ```
  Future<Project> changeMode(
    Project p,
    LabelingMode mode, {
    ModeChangePolicy policy = ModeChangePolicy.deleteAll,
    FutureOr<void> Function({required String projectId, required LabelingMode from, required LabelingMode to, required LabelRepository labels})? migrate,
  }) async {
    if (p.mode == mode) return p;

    // (선택) 사전 점검: 기존 라벨 존재 여부를 가져와 경고/차단 정책에 활용 가능
    final hasAnyLabels = await _labels.hasAny(p.id);
    ProjectValidator.precheckModeChange(project: p, nextMode: mode, hasAnyLabels: hasAnyLabels);

    // 라벨 정리/마이그레이션
    switch (policy) {
      case ModeChangePolicy.deleteAll:
        await _labels.deleteAllLabels(p.id);
        break;
      case ModeChangePolicy.migrateWithStrategy:
        if (migrate == null) {
          throw ArgumentError('ModeChangePolicy.migrateWithStrategy를 사용하려면 migrate 콜백을 제공해야 합니다.');
        }
        await migrate(projectId: p.id, from: p.mode, to: mode, labels: _labels);
        break;
    }

    final np = _touch(p.copyWith(mode: mode));
    return _save(np);
  }

  /// **클래스 추가**.
  ///
  /// - [name]을 트림 후 기존 목록과 Set 합집합으로 중복을 방지한다.
  /// - 전체 클래스 목록을 [ProjectValidator.checkClasses]로 검증한다.
  /// - 성공 시 저장 후 변경 스냅샷을 반환한다.
  Future<Project> addClass(Project p, String name) async {
    final set = {...p.classes, name.trim()};
    final classes = set.toList();
    ProjectValidator.checkClasses(classes);
    final np = _touch(p.copyWith(classes: classes));
    return _save(np);
  }

  /// **클래스 이름 수정**.
  ///
  /// - [index] 범위를 체크하고, 해당 위치의 이름을 [newName]으로 치환한다.
  /// - 전체 클래스 목록을 [ProjectValidator.checkClasses]로 검증한다.
  /// - 성공 시 저장 후 변경 스냅샷을 반환한다.
  Future<Project> editClass(Project p, int index, String newName) async {
    if (index < 0 || index >= p.classes.length) {
      throw RangeError.index(index, p.classes, 'index');
    }
    final classes = [...p.classes]..[index] = newName.trim();
    ProjectValidator.checkClasses(classes);
    final np = _touch(p.copyWith(classes: classes));
    return _save(np);
  }

  /// **클래스 삭제**.
  ///
  /// - [index] 범위를 체크하고 해당 항목을 제거한다.
  /// - 빈 목록/중복 등은 [ProjectValidator.checkClasses]에서 최종 검증한다.
  /// - 성공 시 저장 후 변경 스냅샷을 반환한다.
  Future<Project> removeClass(Project p, int index) async {
    if (index < 0 || index >= p.classes.length) {
      throw RangeError.index(index, p.classes, 'index');
    }
    final classes = [...p.classes]..removeAt(index);
    ProjectValidator.checkClasses(classes);
    final np = _touch(p.copyWith(classes: classes));
    return _save(np);
  }

  /// **데이터(DataInfo) 여러 건 추가**.
  ///
  /// - UI에서는 플랫폼별 파일 선택/드래그탑입(drop) 등을 처리하여 [infos]만 전달한다.
  /// - 기존 목록 뒤에 병합하며, 병합 결과는 [ProjectValidator.checkDataInfos]로 검증한다.
  /// - 성공 시 저장 후 변경 스냅샷을 반환한다.
  Future<Project> addDataInfos(Project p, List<DataInfo> infos) async {
    final list = [...p.dataInfos, ...infos];
    ProjectValidator.checkDataInfos(list);
    final np = _touch(p.copyWith(dataInfos: list));
    return _save(np);
  }

  /// **데이터 한 건 삭제**.
  ///
  /// - [index] 범위를 체크하고 해당 항목을 제거한다.
  /// - 결과 목록은 [ProjectValidator.checkDataInfos]로 검증한다.
  /// - 성공 시 저장 후 변경 스냅샷을 반환한다.
  Future<Project> removeDataInfo(Project p, int index) async {
    if (index < 0 || index >= p.dataInfos.length) {
      throw RangeError.index(index, p.dataInfos, 'index');
    }
    final list = [...p.dataInfos]..removeAt(index);
    ProjectValidator.checkDataInfos(list);
    final np = _touch(p.copyWith(dataInfos: list));
    return _save(np);
  }

  /// **데이터 세트 교체(대량 교체)**.
  ///
  /// - 외부에서 신규 데이터 셋 전체를 구성해 넘기는 경우 사용한다.
  /// - [infos] 전체를 [ProjectValidator.checkDataInfos]로 검증한다.
  /// - 성공 시 저장 후 변경 스냅샷을 반환한다.
  Future<Project> setDataInfos(Project p, List<DataInfo> infos) async {
    ProjectValidator.checkDataInfos(infos);
    final np = _touch(p.copyWith(dataInfos: [...infos]));
    return _save(np);
  }
}
