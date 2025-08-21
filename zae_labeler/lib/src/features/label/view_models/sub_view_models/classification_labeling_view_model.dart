// 📁 lib/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart

import 'package:zae_labeler/src/core/models/data/unified_data.dart';

import '../label_view_model.dart';
import 'base_labeling_view_model.dart';
import '../../../../core/models/label/classification_label_model.dart';

/// ViewModel for single and multi classification labeling modes.
/// Handles label toggling and status tracking per data item.
class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases});

  /// 단일/다중 분류 공통: 임의 입력을 현재 라벨에 반영 후 저장
  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = labelManager.currentLabelVM;
    if (labelVM == null) return;

    await labelVM.updateLabelFromInput(labelData);
    await labelVM.saveLabel();

    await recomputeSummary();
    notifyListeners();
  }

  /// 다중 분류 토글 또는 단일 분류 클릭 토글
  Future<void> toggleLabel(String labelItem) async {
    final labelVM = labelManager.currentLabelVM;
    if (labelVM == null) return;

    await labelVM.toggleLabel(labelItem);
    await labelVM.saveLabel();

    await recomputeSummary();
    notifyListeners();
  }

  /// 현재 데이터에서 라벨이 선택되어 있는지(분류 전용)
  bool isLabelSelected(String labelItem) {
    final labelVM = labelManager.currentLabelVM;
    return labelVM?.isLabelSelected(labelItem) ?? false;
  }
}

/// ViewModel for cross classification mode, labeling pairs of data.
/// Uses nC2 pairing logic and custom progress tracking per relation.
class CrossClassificationLabelingViewModel extends LabelingViewModel {
  CrossClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases});

  int _sourceIndex = 0;
  int _targetIndex = 1;

  late List<String> _selectedDataIds; // dataIds participating in cross labeling
  late List<CrossDataPair> _crossPairs; // all nC2 pairs (sourceId,targetId,relation)

  // ──────────────────────────────────────────────────────────────────────────
  // Cross-progression: pair-based metrics (override base summary accessors)
  // ──────────────────────────────────────────────────────────────────────────
  @override
  int get totalCount => _crossPairs.length;

  @override
  int get completeCount => _crossPairs.where((e) => e.relation.isNotEmpty).length;

  @override
  int get warningCount => 0;

  @override
  int get incompleteCount => totalCount - completeCount;

  @override
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  int get selectedLength => _selectedDataIds.length;

  int get currentPairIndex => _sourceIndex * (selectedLength - 1) - (_sourceIndex * (_sourceIndex - 1)) ~/ 2 + (_targetIndex - _sourceIndex - 1);

  CrossDataPair? get currentPair => (currentPairIndex >= 0 && currentPairIndex < _crossPairs.length) ? _crossPairs[currentPairIndex] : null;

  UnifiedData get currentSourceData => dataManager.allData.firstWhere((e) => e.dataId == _selectedDataIds[_sourceIndex]);

  UnifiedData get currentTargetData => dataManager.allData.firstWhere((e) => e.dataId == _selectedDataIds[_targetIndex]);

  @override
  Future<void> initialize() async {
    await super.initialize();

    // 모든 데이터 참여(필요 시 필터링 로직 주입 가능)
    _selectedDataIds = dataManager.allData.map((e) => e.dataId).toList(growable: false);
    _crossPairs = _generateCrossPairs(_selectedDataIds);
    _sourceIndex = 0;
    _targetIndex = _selectedDataIds.length > 1 ? 1 : 0;

    // 저장된 교차 라벨 로드 → _crossPairs에 반영
    for (int i = 0; i < _crossPairs.length; i++) {
      final pair = _crossPairs[i];
      final vm = _vmForPair(pair); // ← 여기서 UnifiedData를 만들어 넘긴다
      await vm.loadLabel();

      final relation = vm.labelModel.label;
      if (relation != null && relation.toString().isNotEmpty) {
        _crossPairs[i] = pair.copyWith(relation: relation);
      }
    }

    notifyListeners();
  }

  // 분류와 별도 진행률을 갖기 때문에 base의 summary는 사용하지 않음.
  // 다만, 외부 위젯이 base의 summary에 의존한다면 여기에 recomputeSummary()를
  // 추가로 호출해 총괄 요약과의 균형을 맞출 수도 있음.

  /// 현재 페어의 relation을 직접 설정
  @override
  Future<void> updateLabel(dynamic labelData) async {
    final pair = currentPair;
    if (pair == null) return;

    final updated = pair.copyWith(relation: labelData?.toString() ?? '');
    _crossPairs[currentPairIndex] = updated;

    final vm = _vmForPair(updated);
    await vm.updateLabelFromInput(updated);
    await vm.saveLabel();

    notifyListeners();
  }

  /// relation 토글(같은 relation 다시 누르면 해제하는 UX가 필요하면 여기서 구현)
  Future<void> toggleLabel(String relation) async {
    final pair = currentPair;
    if (pair == null) return;

    final toggled = pair.relation == relation ? '' : relation;
    await updateLabel(toggled);
  }

  bool isLabelSelected(String relation) {
    final pair = currentPair;
    return pair?.relation == relation;
  }

  @override
  Future<void> moveNext() async {
    if (selectedLength < 2) return;

    if (_targetIndex < selectedLength - 1) {
      _targetIndex++;
    } else if (_sourceIndex < selectedLength - 2) {
      _sourceIndex++;
      _targetIndex = _sourceIndex + 1;
    }
    notifyListeners();
  }

  @override
  Future<void> movePrevious() async {
    if (selectedLength < 2) return;

    if (_targetIndex > _sourceIndex + 1) {
      _targetIndex--;
    } else if (_sourceIndex > 0) {
      _sourceIndex--;
      _targetIndex = selectedLength - 1;
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────
  LabelViewModel _vmForPair(CrossDataPair pair) {
    final id = '${pair.sourceId}_${pair.targetId}';
    return labelManager.getOrCreateLabelVMById(dataId: id, fileName: id);
  }

  List<CrossDataPair> _generateCrossPairs(List<String> ids) {
    final pairs = <CrossDataPair>[];
    for (int i = 0; i < ids.length - 1; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        pairs.add(CrossDataPair(sourceId: ids[i], targetId: ids[j]));
      }
    }
    return pairs;
  }
}
