import 'package:flutter/material.dart';

import '../../models/data_model.dart';
import '../../utils/cross_pairing.dart';
import '../label_view_model.dart';
import 'base_labeling_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';

class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({
    required super.project,
    required super.storageHelper,
  });

  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = currentLabelVM;

    if (labelVM.labelModel is ClassificationLabelModel) {
      final model = labelVM.labelModel as ClassificationLabelModel;
      labelVM.labelModel = model.isMultiClass ? model.toggleLabel(labelData) : model.updateLabel(labelData);

      debugPrint("[ClsLabelingVM.updateLabel] selected: ${labelVM.labelModel.label}");

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
      final model = labelVM.labelModel as ClassificationLabelModel;
      labelVM.labelModel = model.toggleLabel(labelItem);
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

class CrossClassificationLabelingViewModel extends LabelingViewModel {
  CrossClassificationLabelingViewModel({
    required super.project,
    required super.storageHelper,
  });

  int _sourceIndex = 0;
  int _targetIndex = 1; // ✅ 시작은 source 다음 target

  List<String> _selectedDataIds = []; // ✅ 사용자가 선택한 dataId 목록
  List<CrossDataPair> _crossPairs = []; // ✅ 생성된 CrossDataPair 목록

  int get totalPairCount => _crossPairs.length;
  int get currentPairIndex => _sourceIndex * (_selectedDataIds.length - 1) - (_sourceIndex * (_sourceIndex - 1)) ~/ 2 + (_targetIndex - _sourceIndex - 1);
  CrossDataPair? get currentPair => (currentPairIndex >= 0 && currentPairIndex < _crossPairs.length) ? _crossPairs[currentPairIndex] : null;

  // ✅ 초기화 시 선택된 dataIds를 받는다
  Future<void> initializeCrossPairs(List<String> selectedDataIds) async {
    _selectedDataIds = selectedDataIds;
    _crossPairs = generateCrossPairs(selectedDataIds);
    _sourceIndex = 0;
    _targetIndex = 1;
    notifyListeners();
  }

  // ✅ relation을 업데이트하고 저장
  @override
  Future<void> updateLabel(dynamic labelData) async {
    if (currentPair == null) return;

    final updatedPair = currentPair!.copyWith(relation: labelData);
    _crossPairs[currentPairIndex] = updatedPair;

    final labelVM = getOrCreateLabelVMForCrossPair(currentPair!);
    labelVM.labelModel = CrossClassificationLabelModel(label: updatedPair, labeledAt: DateTime.now());

    debugPrint("[CrossClsLabelingVM.updateLabel] source=${updatedPair.sourceId}, target=${updatedPair.targetId}, relation=${updatedPair.relation}");

    await labelVM.saveLabel();
    notifyListeners();
  }

  // ✅ Label toggle (선택/선택 해제) - 여기서는 relation 변경만
  @override
  void toggleLabel(String labelItem) {
    updateLabel(labelItem);
  }

  // ✅ 현재 선택된 relation과 비교
  @override
  bool isLabelSelected(String labelItem) {
    return currentPair?.relation == labelItem;
  }

  /// ✅ 쌍 이동: 다음
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

  /// ✅ 쌍 이동: 이전
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

  /// ✅ CrossPair용 LabelViewModel 생성
  LabelViewModel getOrCreateLabelVMForCrossPair(CrossDataPair pair) {
    final id = "${pair.sourceId}_${pair.targetId}"; // ✅ source와 target을 합친 ID
    return labelCache.putIfAbsent(id, () {
      return LabelViewModelFactory.create(
        projectId: project.id,
        dataId: id,
        dataFilename: id,
        dataPath: '', // 경로는 따로 필요 없음
        mode: project.mode,
        storageHelper: storageHelper,
      );
    });
  }

  /// ✅ 현재 source/target 데이터 가져오기
  UnifiedData get currentSourceData => unifiedDataList.firstWhere((e) => e.dataId == _selectedDataIds[_sourceIndex]);
  UnifiedData get currentTargetData => unifiedDataList.firstWhere((e) => e.dataId == _selectedDataIds[_targetIndex]);
}
