// 📁 sub_view_models/base_labeling_view_model.dart
import 'package:flutter/material.dart';

import '../../domain/app_use_cases.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../../utils/adaptive/adaptive_data_loader.dart';
import '../label_view_model.dart';

/// Abstract base class for all LabelingViewModels.
abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;
  final AppUseCases appUseCases;
  final List<UnifiedData>? initialDataList;

  bool _isInitialized = false;
  final bool _memoryOptimized = false;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Map<String, LabelViewModel> labelCache = {};
  void clearLabelCache() => labelCache.clear();

  LabelingViewModel({required this.project, required this.storageHelper, required this.appUseCases, this.initialDataList});

  bool get isInitialized => _isInitialized;
  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;
  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  String get currentDataFileName => _currentUnifiedData.fileName;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;

  int get totalCount => _unifiedDataList.length;
  int get completeCount => _unifiedDataList.where((e) => e.status == LabelStatus.complete).length;
  int get warningCount => _unifiedDataList.where((e) => e.status == LabelStatus.warning).length;
  int get incompleteCount => totalCount - completeCount;
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  Future<void> initialize() async {
    debugPrint("[LabelingVM.initialize] : ${project.mode}");
    if (_isInitialized && project.mode != currentLabelVM.mode) {
      debugPrint("[LabelingVM.initialize] : LabelVM mismatch!");
      labelCache.clear();
    }

    if (_memoryOptimized) {
      _unifiedDataList = initialDataList ?? [];
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    } else {
      _unifiedDataList = initialDataList ?? await loadDataAdaptively(project, storageHelper);
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }

    await getOrCreateLabelVM().loadLabel();
    await validateLabelModelType();
    await refreshAllStatuses();
    await postInitialize();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> postInitialize() async {}
  Future<void> postMove() async {}

  Future<void> validateLabelModelType() async {
    final labelVM = currentLabelVM;
    if (labelVM.mode != project.mode) {
      debugPrint("⚠️ 라벨 모델 모드 불일치 → 초기화");
      labelCache.remove(_currentUnifiedData.dataId);
      labelVM.labelModel = LabelModelFactory.createNew(project.mode, dataId: _currentUnifiedData.dataId);
      await labelVM.saveLabel();
    }
  }

  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  Future<void> _move(int delta) async {
    final newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < _unifiedDataList.length) {
      _currentIndex = newIndex;
      _currentUnifiedData = _unifiedDataList[newIndex];
      await getOrCreateLabelVM().loadLabel();
      await refreshStatus(currentUnifiedData.dataId);
      await postMove();
      notifyListeners();
    }
  }

  LabelViewModel getOrCreateLabelVM() {
    final id = _currentUnifiedData.dataId;
    return labelCache.putIfAbsent(id, () {
      return LabelViewModelFactory.create(
        projectId: project.id,
        dataId: id,
        dataFilename: _currentUnifiedData.fileName,
        dataPath: _currentUnifiedData.dataPath ?? '',
        mode: project.mode,
        labelUseCases: appUseCases.label,
      );
    });
  }

  Future<void> refreshStatus(String dataId) async {
    final vm = getOrCreateLabelVM();
    await vm.loadLabel();
    final status = appUseCases.label.validation.getStatus(project, vm.labelModel);
    final index = _unifiedDataList.indexWhere((e) => e.dataId == dataId);
    if (index != -1) {
      _unifiedDataList[index] = _unifiedDataList[index].copyWith(status: status);
    }
  }

  Future<void> refreshAllStatuses() async {
    if (project.labels.isEmpty) {
      project.labels = await appUseCases.label.batch.loadAllLabels(project.id);
    }

    for (final data in _unifiedDataList) {
      final vm = labelCache.putIfAbsent(data.dataId, () {
        return LabelViewModelFactory.create(
          projectId: project.id,
          dataId: data.dataId,
          dataFilename: data.fileName,
          dataPath: data.dataPath ?? '',
          mode: project.mode,
          labelUseCases: appUseCases.label,
        );
      });

      await vm.loadLabel();
      final status = appUseCases.label.validation.getStatus(project, vm.labelModel);
      final idx = _unifiedDataList.indexWhere((e) => e.dataId == data.dataId);
      if (idx != -1) {
        _unifiedDataList[idx] = _unifiedDataList[idx].copyWith(status: status);
      }
    }
  }

  Future<void> updateLabel(dynamic labelData);
  void toggleLabel(String labelItem) => throw UnimplementedError();
  bool isLabelSelected(String labelItem) => throw UnimplementedError();

  Future<String> exportAllLabels() async {
    final allLabels = labelCache.values.map((vm) => vm.labelModel).toList();
    final dataInfos = _unifiedDataList.map((e) => e.toDataInfo()).toList();
    return await appUseCases.label.io.exportLabelsWithData(project, allLabels, dataInfos);
  }
}
