// lib/src/features/project/use_cases/edit_project_meta_use_case.dart
import '../../../core/models/project/project_model.dart';
import '../../label/models/label_model.dart'; // LabelingMode를 여기서 가져오는 전제
import '../repository/project_repository.dart';

/// ✅ 프로젝트 메타 수정 유스케이스 (불변 Project 대응)
/// - 엔티티를 직접 변경하지 않고, Repository의 copyWith 기반 업데이트를 호출해
///   새 Project 인스턴스를 받아 반환합니다.
/// - 라벨 초기화 등 저장소/JSON 정합성도 여기서 보장합니다.
class EditProjectMetaUseCase {
  final ProjectRepository repository;

  EditProjectMetaUseCase({required this.repository});

  /// 🔹 프로젝트 이름 변경 및 저장된 최신 Project 반환
  Future<Project?> rename(String projectId, String newName) async {
    // 불변 모델이므로 세터 호출 금지 → Repository의 업데이트 사용
    return repository.updateProjectName(projectId, newName);
  }

  /// 🔹 라벨링 모드 변경 + 라벨 초기화 + 저장된 최신 Project 반환
  ///
  /// 순서:
  /// 1) 현재 프로젝트 조회 (없으면 null)
  /// 2) 모드 동일 시 No-op (바로 반환)
  /// 3) 라벨 스토리지/JSON 동기화 초기화
  /// 4) 모드 업데이트 후 결과 반환
  Future<Project?> changeLabelingMode(String projectId, LabelingMode newMode) async {
    final current = await repository.findById(projectId);
    if (current == null) return null;

    if (current.mode == newMode) {
      // 이미 동일 모드면 굳이 초기화/저장 불필요
      return current;
    }

    // 라벨 정합성: 스토리지와 프로젝트 JSON 양쪽 모두 비우기
    await repository.clearLabels(projectId);
    // JSON 내부 labels 필드까지 반드시 비우고 싶다면:
    await repository.clearLabelsInProjectJson(projectId);

    // 모드 변경 후 최신 Project 반환
    final updated = await repository.updateProjectMode(projectId, newMode);
    return updated;
  }

  /// 🔹 프로젝트의 모든 라벨 초기화
  ///
  /// 주의: 스토리지 삭제만으로 충분하지 않다면 JSON 내부 labels도 비워서
  ///       UI/동기화 불일치를 방지하세요.
  Future<void> clearLabels(String projectId) async {
    await repository.clearLabels(projectId);
    await repository.clearLabelsInProjectJson(projectId);
  }
}
