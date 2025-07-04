import '../../features/label/view_models/label_view_model.dart';
import '../../core/models/project_model.dart';
import '../../features/label/use_cases/label_use_cases.dart';

/// 🏷️ LabelManager
/// - LabelViewModel의 생성, 캐싱, 라벨 저장 및 불러오기 담당.
/// - 라벨 캐시를 유지하고 데이터 단위로 라벨을 관리함.
///
/// 주요 책임:
/// - getOrCreateLabelVM
/// - saveLabel, loadLabel
/// - toggle, update
class LabelManager {
  final Project project;
  final LabelUseCases useCases;

  final Map<String, LabelViewModel> _labelCache = {};

  LabelManager({required this.project, required this.useCases});

  /// 라벨 뷰모델을 생성하거나 기존 것을 반환
  LabelViewModel getOrCreate(String dataId) {
    // TODO: 라벨 캐시 활용
    throw UnimplementedError();
  }

  /// 주어진 데이터에 대해 라벨 불러오기
  Future<void> load(String dataId) async {
    // TODO: 내부 cache로부터
  }

  /// 주어진 데이터에 대해 라벨 저장
  Future<void> save(String dataId) async {
    // TODO: 저장 처리
  }

  /// 현재 라벨에 대해 labelData를 toggle 또는 update
  Future<void> updateLabel(String dataId, dynamic labelData) async {
    // TODO: 단일/다중 classification 분기 처리
  }

  void clearCache() {
    _labelCache.clear();
  }
}
