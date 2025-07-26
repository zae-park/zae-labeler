// 📁 sub_view_models/base_labeling_view_model.dart

import '../../../../core/models/data_model.dart';
import '../label_view_model.dart';
import 'base_labeling_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';

/// ViewModel for single and multi classification labeling modes.
/// Handles label toggling and status tracking per data item.
class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases, super.initialDataList});

  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = labelManager.currentLabelVM;
    await labelVM!.updateLabelFromInput(labelData);
    await labelManager.refreshStatusFor(dataManager.currentData, (status) {
      dataManager.updateStatus(dataManager.currentData.dataId, status);
    });
    notifyListeners();
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    final labelVM = labelManager.currentLabelVM;
    await labelVM!.toggleLabel(labelItem);
    await labelManager.refreshStatusFor(dataManager.currentData, (status) {
      dataManager.updateStatus(dataManager.currentData.dataId, status);
    });
    notifyListeners();
  }

  @override
  bool isLabelSelected(String labelItem) {
    final labelVM = labelManager.currentLabelVM;
    return labelVM?.isLabelSelected(labelItem) ?? false;
  }
}

/// ViewModel for cross classification mode, labeling pairs of data.
/// Uses nC2 pairing logic and custom progress tracking per relation.
class CrossClassificationLabelingViewModel extends LabelingViewModel {
  CrossClassificationLabelingViewModel({
    required super.project,
    required super.storageHelper,
    required super.appUseCases,
    super.initialDataList,
  });

  int _sourceIndex = 0;
  int _targetIndex = 1;

  List<String> _selectedDataIds = [];
  List<CrossDataPair> _crossPairs = [];

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

  int get currentPairIndex => _sourceIndex * (selectedLength - 1) - (_sourceIndex * (_sourceIndex - 1)) ~/ 2 + (_targetIndex - _sourceIndex - 1);

  int get selectedLength => _selectedDataIds.length;

  CrossDataPair? get currentPair => (currentPairIndex >= 0 && currentPairIndex < _crossPairs.length) ? _crossPairs[currentPairIndex] : null;

  UnifiedData get currentSourceData => dataManager.allData.firstWhere((e) => e.dataId == _selectedDataIds[_sourceIndex]);
  UnifiedData get currentTargetData => dataManager.allData.firstWhere((e) => e.dataId == _selectedDataIds[_targetIndex]);

  @override
  Future initialize() async {
    await super.initialize();

    _selectedDataIds = dataManager.allData.map((e) => e.dataId).toList();
    _crossPairs = generateCrossPairs(_selectedDataIds);
    _sourceIndex = 0;
    _targetIndex = 1;

    // 저장된 교차 라벨을 로드하여 _crossPairs에 반영
    for (int i = 0; i < _crossPairs.length; i++) {
      final pair = _crossPairs[i];
      // pair sourceId와 targetId를 조합한 데이터ID로 라벨을 읽어온다.
      final id = '${pair.sourceId}_${pair.targetId}';
      final vm = labelManager.getOrCreateLabelVM(dataId: id, filename: id, path: '', mode: project.mode);
      // 기존 라벨을 저장소에서 불러온다.
      await vm.loadLabel();
      final relation = vm.labelModel.label;
      if (relation != null && relation.toString().isNotEmpty) {
        _crossPairs[i] = pair.copyWith(relation: relation);
      }
    }

    // 라벨 상태가 반영되었음을 알리기 위해 notifyListeners 호출
    notifyListeners();
  }

  @override
  Future<void> updateLabel(dynamic labelData) async {
    if (currentPair == null) return;

    final updatedPair = currentPair!.copyWith(relation: labelData);
    _crossPairs[currentPairIndex] = updatedPair;

    final labelVM = getOrCreateLabelVMForCrossPair(updatedPair);
    labelVM.updateLabelFromInput(updatedPair);
    await labelVM.saveLabel();

    notifyListeners();
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    if (currentPair == null) return;

    final updatedPair = currentPair!.copyWith(relation: labelItem);
    _crossPairs[currentPairIndex] = updatedPair;

    final labelVM = getOrCreateLabelVMForCrossPair(currentPair!);
    labelVM.toggleLabel(labelItem);
    await labelVM.saveLabel();

    notifyListeners();
  }

  @override
  bool isLabelSelected(String labelItem) {
    if (currentPair == null) return false;
    return getOrCreateLabelVMForCrossPair(currentPair!).isLabelSelected(labelItem);
  }

  @override
  Future<void> moveNext() async {
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
    if (_targetIndex > _sourceIndex + 1) {
      _targetIndex--;
    } else if (_sourceIndex > 0) {
      _sourceIndex--;
      _targetIndex = selectedLength - 1;
    }
    notifyListeners();
  }

  LabelViewModel getOrCreateLabelVMForCrossPair(CrossDataPair pair) {
    String id = "${pair.sourceId}_${pair.targetId}";
    return labelManager.getOrCreateLabelVM(dataId: id, filename: id, path: '', mode: project.mode);
  }

  List<CrossDataPair> generateCrossPairs(List<String> ids) {
    final pairs = <CrossDataPair>[];
    for (int i = 0; i < ids.length - 1; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        pairs.add(CrossDataPair(sourceId: ids[i], targetId: ids[j]));
      }
    }
    return pairs;
  }
}
