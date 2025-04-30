// 📁 sub_view_models/base_labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/label_model.dart';
import '../../utils/label_validator.dart';
import '../label_view_model.dart';
import '../../models/data_model.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';

/// Abstract base class for all LabelingViewModels.
/// Provides core data loading, navigation, label caching, and progress tracking logic.
/// Subclasses must override the progress tracking methods to customize behavior for each labeling mode.
abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;

  bool _isInitialized = false;
  final bool _memoryOptimized = false;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Map<String, LabelViewModel> labelCache = {};

  LabelingViewModel({required this.project, required this.storageHelper});

  /// Indicates whether the ViewModel has completed initialization
  bool get isInitialized => _isInitialized;

  /// Index of the currently selected data item
  int get currentIndex => _currentIndex;

  /// All data items associated with this project
  List<UnifiedData> get unifiedDataList => _unifiedDataList;

  /// The currently active data item
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  /// Returns the LabelViewModel associated with the current data item
  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  /// Convenience accessors for the current data item
  String get currentDataFileName => _currentUnifiedData.fileName;
  File? get currentImageFile => _currentUnifiedData.file;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;

  /// Total number of items to label (must be overridden in subclasses)
  int get totalCount => _unifiedDataList.length;

  /// Number of items that are fully labeled (must be overridden in subclasses)
  int get completeCount => _unifiedDataList.where((e) => e.status == LabelStatus.complete).length;

  /// Number of items with warnings (optional override)
  int get warningCount => _unifiedDataList.where((e) => e.status == LabelStatus.warning).length;

  /// Number of incomplete items
  int get incompleteCount => totalCount - completeCount;

  /// Labeling progress ratio (0.0 ~ 1.0)
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  /// Initializes all unified data and label cache
  Future<void> initialize() async {
    debugPrint("[LabelingVM.initialize] : \${project.mode}");
    if (_memoryOptimized) {
      _unifiedDataList.clear();
      _currentUnifiedData = project.dataPaths.isNotEmpty ? await UnifiedData.fromDataPath(project.dataPaths.first) : UnifiedData.empty();
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map(UnifiedData.fromDataPath));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }

    await getOrCreateLabelVM().loadLabel();
    await validateLabelModelType();
    await refreshAllStatuses();
    await postInitialize();

    _isInitialized = true;
    notifyListeners();
  }

  /// Optional hook for additional logic after initialization
  Future<void> postInitialize() async {}

  /// Optional hook for logic after moving to a new item
  Future<void> postMove() async {}

  /// Ensures that the current LabelModel type matches the project mode
  Future<void> validateLabelModelType() async {
    final labelVM = currentLabelVM;
    final expected = LabelModelFactory.createNew(project.mode);
    if (labelVM.labelModel.runtimeType != expected.runtimeType) {
      debugPrint("⚠️ 라벨 모델 타입 불일치 → 초기화");
      labelVM.labelModel = expected;
      await labelVM.saveLabel();
    }
  }

  /// Move to the next or previous item
  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  Future<void> _move(int delta) async {
    final newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
      await getOrCreateLabelVM().loadLabel();
      await refreshStatus(currentUnifiedData.dataId);
      await postMove();
      notifyListeners();
    }
  }

  /// Returns the LabelViewModel for the current item, or creates one if not cached
  LabelViewModel getOrCreateLabelVM() {
    final id = _currentUnifiedData.dataId;
    return labelCache.putIfAbsent(id, () {
      return LabelViewModelFactory.create(
        projectId: project.id,
        dataId: id,
        dataFilename: _currentUnifiedData.fileName,
        dataPath: _currentUnifiedData.file?.path ?? '',
        mode: project.mode,
        storageHelper: storageHelper,
      );
    });
  }

  /// Refreshes the label status of a single data item
  Future<void> refreshStatus(String dataId) async {
    final vm = getOrCreateLabelVM();
    await vm.loadLabel();
    final status = LabelValidator.getStatus(project, vm.labelModel);
    final index = _unifiedDataList.indexWhere((e) => e.dataId == dataId);
    if (index != -1) {
      _unifiedDataList[index] = _unifiedDataList[index].copyWith(status: status);
    }
  }

  /// Refreshes all statuses in the dataset
  Future<void> refreshAllStatuses() async {
    for (final data in _unifiedDataList) {
      final vm = getOrCreateLabelVM();
      await vm.loadLabel();
      final status = LabelValidator.getStatus(project, vm.labelModel);
      final idx = _unifiedDataList.indexWhere((e) => e.dataId == data.dataId);
      if (idx != -1) {
        _unifiedDataList[idx] = _unifiedDataList[idx].copyWith(status: status);
      }
    }
  }

  /// Applies a new label (must be implemented by subclass)
  Future<void> updateLabel(dynamic labelData);

  /// Toggles label state (optional override)
  void toggleLabel(String labelItem) => throw UnimplementedError();

  /// Checks if a label is selected (optional override)
  bool isLabelSelected(String labelItem) => throw UnimplementedError();

  /// Exports all label models to file via storage helper
  Future<String> exportAllLabels() async {
    final allLabels = labelCache.values.map((vm) => vm.labelModel).toList();
    return await storageHelper.exportAllLabels(project, allLabels, project.dataPaths);
  }
}
