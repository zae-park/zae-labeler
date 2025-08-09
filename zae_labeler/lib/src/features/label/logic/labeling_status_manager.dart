import 'package:zae_labeler/src/features/label/use_cases/validate_label_use_case.dart';

import '../../project/models/project_model.dart';
import '../models/label_model.dart';
import '../../../core/models/data_model.dart';
import '../use_cases/label_use_cases.dart';
import '../view_models/label_view_model.dart';

/// ✅ StatusManager
/// - 프로젝트 설정 및 라벨 모델을 기반으로 상태(`LabelStatus`)를 계산하고 업데이트
///
/// 주요 책임:
/// - 단일 데이터에 대한 상태 갱신
/// - 전체 데이터에 대한 상태 갱신
class StatusManager {
  final Project project;
  final LabelValidationUseCase validation;

  StatusManager({required this.project, required LabelUseCases useCases}) : validation = useCases.validation;

  LabelStatus getStatus(LabelModel model) {
    return validation.getStatus(project, model);
  }

  /// 단일 데이터 상태 갱신
  Future<LabelStatus> refreshStatus(UnifiedData data, LabelViewModel labelVM) async {
    // 라벨이 로드되어 있지 않다면 로드
    if (labelVM.labelModel.dataId != data.dataId) {
      await labelVM.loadLabel();
    }
    final status = getStatus(labelVM.labelModel);
    // 여기서 데이터 객체의 status 필드를 갱신하거나 반환만 할 수 있습니다.
    return status;
  }

  /// 모든 데이터 상태 갱신. Map<데이터ID, 상태> 반환
  Future<Map<String, LabelStatus>> refreshAll(List<UnifiedData> dataList, Map<String, LabelViewModel> labelVMs) async {
    final Map<String, LabelStatus> result = {};
    for (final data in dataList) {
      final vm = labelVMs[data.dataId]!;
      await vm.loadLabel();
      final status = getStatus(vm.labelModel);
      result[data.dataId] = status;
    }
    return result;
  }
}
