// 📁 sub_view_models/base_labeling_view_model.dart
import 'package:flutter/material.dart';

import '../../models/data_model.dart';
import '../../utils/cross_pairing.dart';
import '../label_view_model.dart';
import 'base_labeling_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';

/// ViewModel for single and multi classification labeling modes.
/// Handles label toggling and status tracking per data item.
class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases, super.initialDataList});

  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = currentLabelVM;
    labelVM.updateLabel(labelData); // ✅ LabelViewModel 내부 책임으로 위임
    await refreshStatus(currentUnifiedData.dataId);
    notifyListeners();
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    final labelVM = currentLabelVM;
    labelVM.toggleLabel(labelItem);
    await refreshStatus(currentUnifiedData.dataId);
    notifyListeners();
  }

  @override
  bool isLabelSelected(String labelItem) => currentLabelVM.isLabelSelected(labelItem);
}

/// ViewModel for cross classification mode, labeling pairs of data.
/// Uses nC2 pairing logic and custom progress tracking per relation.
class CrossClassificationLabelingViewModel extends LabelingViewModel {
  CrossClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.appUseCases, super.initialDataList});

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

  int get currentPairIndex => _sourceIndex * (_selectedDataIds.length - 1) - (_sourceIndex * (_sourceIndex - 1)) ~/ 2 + (_targetIndex - _sourceIndex - 1);

  CrossDataPair? get currentPair => (currentPairIndex >= 0 && currentPairIndex < _crossPairs.length) ? _crossPairs[currentPairIndex] : null;

  @override
  Future<void> initialize() async {
    await super.initialize();
    _selectedDataIds = unifiedDataList.map((e) => e.dataId).toList();
    _crossPairs = generateCrossPairs(_selectedDataIds);
    _sourceIndex = 0;
    _targetIndex = 1;
  }

  @override
  Future<void> updateLabel(dynamic labelData) async {
    if (currentPair == null) return;

    final updatedPair = currentPair!.copyWith(relation: labelData);
    _crossPairs[currentPairIndex] = updatedPair;

    final labelVM = getOrCreateLabelVMForCrossPair(updatedPair);
    labelVM.updateLabel(updatedPair);

    debugPrint("[CrossClsLabelingVM.updateLabel] source=\${updatedPair.sourceId}, target=\${updatedPair.targetId}, relation=\${updatedPair.relation}");

    await labelVM.saveLabel();
    notifyListeners();
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    if (currentPair == null) return;
    final labelVM = getOrCreateLabelVMForCrossPair(currentPair!);
    labelVM.toggleLabel(labelItem);
    await refreshStatus("${currentPair!.sourceId}_${currentPair!.targetId}");
    notifyListeners();
  }

  @override
  bool isLabelSelected(String labelItem) {
    if (currentPair == null) return false;
    final labelVM = getOrCreateLabelVMForCrossPair(currentPair!);
    return labelVM.isLabelSelected(labelItem);
  }

  @override
  Future<void> moveNext() async {
    if (_targetIndex < _selectedDataIds.length - 1) {
      _targetIndex++;
    } else if (_sourceIndex < _selectedDataIds.length - 2) {
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
      _targetIndex = _selectedDataIds.length - 1;
    }
    notifyListeners();
  }

  LabelViewModel getOrCreateLabelVMForCrossPair(CrossDataPair pair) {
    String id = "${pair.sourceId}_${pair.targetId}";
    return labelCache.putIfAbsent(
      id,
      () =>
          LabelViewModelFactory.create(projectId: project.id, dataId: id, dataFilename: id, dataPath: '', mode: project.mode, labelUseCases: appUseCases.label),
    );
  }

  UnifiedData get currentSourceData => unifiedDataList.firstWhere((e) => e.dataId == _selectedDataIds[_sourceIndex]);
  UnifiedData get currentTargetData => unifiedDataList.firstWhere((e) => e.dataId == _selectedDataIds[_targetIndex]);
}
