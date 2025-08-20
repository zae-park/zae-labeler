// lib/src/features/label/services/status_manager.dart
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart';

/// ✅ StatusManager
/// - 프로젝트 설정 및 저장된 라벨을 기반으로 상태(LabelStatus)를 계산.
/// - LabelViewModel에 의존하지 않고, LabelUseCases 파사드만 의존.
/// - 단건/일괄 계산을 모두 지원.
class StatusManager {
  final Project project;
  final LabelUseCases useCases;

  StatusManager({required this.project, required this.useCases});

  /// 지정된 라벨의 상태 계산(검증 포함).
  LabelStatus statusOfLabel(LabelModel label) {
    return useCases.statusOf(project, label);
  }

  /// 단일 데이터(UnifiedData)의 상태 계산.
  /// - 필요 시 라벨을 로드하거나 없으면 생성한 뒤 상태를 계산합니다.
  Future<LabelStatus> refreshStatus(UnifiedData data) async {
    final label = await useCases.loadOrCreate(projectId: project.id, dataId: data.dataId, dataPath: data.dataInfo.filePath ?? '', mode: project.mode);
    return statusOfLabel(label);
  }

  /// 여러 데이터의 상태를 일괄 계산.
  /// - 1회 I/O로 labelMap을 불러와 매핑해 성능을 개선합니다.
  Future<Map<String, LabelStatus>> refreshAll(List<UnifiedData> dataList) async {
    final map = await useCases.loadMap(project.id);
    final result = <String, LabelStatus>{};

    for (final d in dataList) {
      final label = map[d.dataId];
      // 라벨이 아직 없다면 기본(미완료)로 간주하거나 필요 시 즉시 생성 후 계산할 수도 있음.
      if (label == null) {
        result[d.dataId] = LabelStatus.incomplete;
        continue;
        // 혹은 아래처럼 생성 후 계산:
        // final created = await useCases.loadOrCreate(
        //   projectId: project.id, dataId: d.dataId, dataPath: d.dataPath ?? '', mode: project.mode);
        // result[d.dataId] = statusOfLabel(created);
      }
      result[d.dataId] = statusOfLabel(label);
    }

    return result;
  }
}
