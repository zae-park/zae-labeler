import '../../features/project/models/project_model.dart';
import '../../features/label/models/label_model.dart';
import '../../core/models/data_model.dart';
import '../../features/label/use_cases/label_use_cases.dart';
import '../../features/label/view_models/label_view_model.dart';

/// ✅ StatusManager
/// - 프로젝트 설정 및 라벨 모델을 기반으로 상태(`LabelStatus`)를 계산하고 업데이트
///
/// 주요 책임:
/// - 단일 데이터에 대한 상태 갱신
/// - 전체 데이터에 대한 상태 갱신
class StatusManager {
  final Project project;
  final LabelUseCases useCases;

  StatusManager({required this.project, required this.useCases});

  /// 주어진 labelModel에 대해 상태를 계산
  LabelStatus getStatus(LabelModel model) {
    return useCases.validation.getStatus(project, model);
  }

  /// 단일 UnifiedData의 상태 갱신
  Future<LabelStatus> refreshStatus(UnifiedData data, LabelViewModel labelVM) async {
    // TODO: getStatus 호출 후 반환
    throw UnimplementedError();
  }

  /// 전체 데이터 상태 갱신
  Future<Map<String, LabelStatus>> refreshAll(List<UnifiedData> dataList, Map<String, LabelViewModel> labelVMs) async {
    // TODO: 반복하여 상태 계산 후 Map 반환
    throw UnimplementedError();
  }
}
