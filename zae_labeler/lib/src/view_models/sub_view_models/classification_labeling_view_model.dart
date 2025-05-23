// 📁 sub_view_models/base_labeling_view_model.dart
import 'package:flutter/material.dart';

import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../../utils/cross_pairing.dart';
import '../label_view_model.dart';
import 'base_labeling_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';

/// ViewModel for single and multi classification labeling modes.
/// Handles label toggling and status tracking per data item.
class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({required super.project, required super.storageHelper, super.initialDataList});

  @override
  int get totalCount => unifiedDataList.length;

  @override
  int get completeCount => unifiedDataList.where((e) => e.status == LabelStatus.complete).length;

  @override
  int get warningCount => unifiedDataList.where((e) => e.status == LabelStatus.warning).length;

  @override
  int get incompleteCount => totalCount - completeCount;

  @override
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  /// Updates the current data's label with new input
  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = currentLabelVM;

    if (labelVM.labelModel is ClassificationLabelModel) {
      final model = labelVM.labelModel as ClassificationLabelModel;
      labelVM.labelModel = model.isMultiClass ? model.toggleLabel(labelData) : model.updateLabel(labelData);

      debugPrint("[ClsLabelingVM.updateLabel] selected: \${labelVM.labelModel.label}");

      await labelVM.saveLabel();
      await refreshStatus(currentUnifiedData.dataId);

      notifyListeners();
    } else if (labelVM.labelModel is SegmentationLabelModel) {
      throw UnimplementedError('SegmentationLabelModel은 ClassificationLabelingViewModel에서 지원하지 않습니다.');
    }
  }

  @override
  void toggleLabel(String labelItem) {
    final labelVM = currentLabelVM;

    if (labelVM.labelModel is ClassificationLabelModel) {
      labelVM.labelModel = (labelVM.labelModel as ClassificationLabelModel).toggleLabel(labelItem);
      notifyListeners();
    }
  }

  @override
  bool isLabelSelected(String labelItem) {
    final model = currentLabelVM.labelModel;
    if (model is ClassificationLabelModel) {
      return model.isSelected(labelItem);
    }
    return false;
  }
}

/// ViewModel for cross classification mode, labeling pairs of data.
/// Uses nC2 pairing logic and custom progress tracking per relation.
class CrossClassificationLabelingViewModel extends LabelingViewModel {
  CrossClassificationLabelingViewModel({required super.project, required super.storageHelper, super.initialDataList});

  int _sourceIndex = 0;
  int _targetIndex = 1;

  List<String> _selectedDataIds = [];
  List<CrossDataPair> _crossPairs = [];

  /// Total number of data pairs to label
  @override
  int get totalCount => totalPairCount;

  /// Number of pairs with a valid relation label
  @override
  int get completeCount => _crossPairs.where((e) => e.relation.isNotEmpty).length;

  /// Not used in this mode
  @override
  int get warningCount => 0;

  /// Number of unlabeled pairs
  @override
  int get incompleteCount => totalCount - completeCount;

  /// Progress ratio for labeled pairs
  @override
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  int get totalPairCount => _crossPairs.length;

  int get currentPairIndex => _sourceIndex * (_selectedDataIds.length - 1) - (_sourceIndex * (_sourceIndex - 1)) ~/ 2 + (_targetIndex - _sourceIndex - 1);

  CrossDataPair? get currentPair => (currentPairIndex >= 0 && currentPairIndex < _crossPairs.length) ? _crossPairs[currentPairIndex] : null;

  /// Initializes nC2 data pair structure after loading unified data
  @override
  Future<void> initialize() async {
    await super.initialize();
    _selectedDataIds = unifiedDataList.map((e) => e.dataId).toList();
    _crossPairs = generateCrossPairs(_selectedDataIds);
    _sourceIndex = 0;
    _targetIndex = 1;
  }

  /// Updates the current pair's label and saves
  @override
  Future<void> updateLabel(dynamic labelData) async {
    if (currentPair == null) return;

    final updatedPair = currentPair!.copyWith(relation: labelData);
    _crossPairs[currentPairIndex] = updatedPair;

    final labelVM = getOrCreateLabelVMForCrossPair(updatedPair);
    labelVM.labelModel =
        CrossClassificationLabelModel(dataId: '${updatedPair.sourceId}_${updatedPair.targetId}', label: updatedPair, labeledAt: DateTime.now());

    debugPrint("[CrossClsLabelingVM.updateLabel] source=\${updatedPair.sourceId}, target=\${updatedPair.targetId}, relation=\${updatedPair.relation}");

    await labelVM.saveLabel();
    notifyListeners();
  }

  @override
  void toggleLabel(String labelItem) {
    updateLabel(labelItem);
  }

  @override
  bool isLabelSelected(String labelItem) {
    return currentPair?.relation == labelItem;
  }

  /// Moves to the next pair in sequence
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

  /// Moves to the previous pair in sequence
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

  /// Gets or creates a label VM for a specific pair
  LabelViewModel getOrCreateLabelVMForCrossPair(CrossDataPair pair) {
    String id = "\${pair.sourceId}_\${pair.targetId}";
    return labelCache.putIfAbsent(id, () {
      return LabelViewModelFactory.create(
        projectId: project.id,
        dataId: id,
        dataFilename: id,
        dataPath: '',
        mode: project.mode,
        storageHelper: storageHelper,
      );
    });
  }

  /// Access the current pair's data items
  UnifiedData get currentSourceData => unifiedDataList.firstWhere((e) => e.dataId == _selectedDataIds[_sourceIndex]);

  UnifiedData get currentTargetData => unifiedDataList.firstWhere((e) => e.dataId == _selectedDataIds[_targetIndex]);
}
