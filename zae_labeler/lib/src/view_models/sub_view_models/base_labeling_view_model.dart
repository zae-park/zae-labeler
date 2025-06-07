// 📁 sub_view_models/base_labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/label_model.dart';
import '../label_view_model.dart';
import '../../models/data_model.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../../utils/adaptive/adaptive_data_loader.dart';
import '../../repositories/label_repository.dart';

/// Abstract base class for all LabelingViewModels.
///
/// ✅ 역할:
/// - 프로젝트 데이터를 불러와 `UnifiedData` 리스트를 구성하고,
/// - 해당 데이터를 순회하며 라벨을 로드, 저장, 상태 추적을 수행합니다.
/// - 세부 라벨링 동작은 하위 ViewModel이 override 합니다.
///
/// ✅ 플랫폼 대응:
/// - Web과 Native 간 파일 접근 방식 차이를 `loadDataAdaptively()`로 추상화하여,
///   플랫폼 독립적인 데이터 로딩 구조를 유지합니다.
///
/// ✅ 메모리 최적화 모드:
/// - `initialDataList`를 주입받은 경우, 미리 주어진 데이터로만 작동하며,
/// - 디스크 로딩이 제한되거나 느린 환경에서의 성능 향상을 위해 사용됩니다.
abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;
  final List<UnifiedData>? initialDataList;
  final LabelRepository labelRepository;

  bool _isInitialized = false;
  final bool _memoryOptimized = false;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Map<String, LabelViewModel> labelCache = {};
  void clearLabelCache() => labelCache.clear();

  LabelingViewModel({
    required this.project,
    required this.storageHelper,
    required this.labelRepository,
    this.initialDataList,
  });

  bool get isInitialized => _isInitialized;
  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;
  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  String get currentDataFileName => _currentUnifiedData.fileName;
  File? get currentImageFile => _currentUnifiedData.file;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;

  int get totalCount => _unifiedDataList.length;
  int get completeCount => _unifiedDataList.where((e) => e.status == LabelStatus.complete).length;
  int get warningCount => _unifiedDataList.where((e) => e.status == LabelStatus.warning).length;
  int get incompleteCount => totalCount - completeCount;
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  /// Initializes the ViewModel by loading data and label information.
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
      if (initialDataList != null) {
        _unifiedDataList = initialDataList!;
      } else {
        _unifiedDataList = await loadDataAdaptively(project, storageHelper);
      }
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
      await labelRepository.saveLabel(
        projectId: project.id,
        dataId: _currentUnifiedData.dataId,
        dataPath: _currentUnifiedData.file?.path ?? '',
        labelModel: labelVM.labelModel,
      );
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
        dataPath: _currentUnifiedData.file?.path ?? '',
        mode: project.mode,
        storageHelper: storageHelper,
        labelRepository: labelRepository,
      );
    });
  }

  Future<void> refreshStatus(String dataId) async {
    final vm = getOrCreateLabelVM();
    await vm.loadLabel();
    final status = labelRepository.getStatus(project, vm.labelModel);
    final index = _unifiedDataList.indexWhere((e) => e.dataId == dataId);
    if (index != -1) {
      _unifiedDataList[index] = _unifiedDataList[index].copyWith(status: status);
    }
  }

  Future<void> refreshAllStatuses() async {
    if (project.labels.isEmpty) {
      project.labels = await labelRepository.loadAllLabels(project.id);
    }

    for (final data in _unifiedDataList) {
      final vm = labelCache.putIfAbsent(data.dataId, () {
        return LabelViewModelFactory.create(
          projectId: project.id,
          dataId: data.dataId,
          dataFilename: data.fileName,
          dataPath: data.file?.path ?? '',
          mode: project.mode,
          storageHelper: storageHelper,
          labelRepository: labelRepository,
        );
      });

      await vm.loadLabel();
      final status = labelRepository.getStatus(project, vm.labelModel);
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
    return await labelRepository.exportLabelsWithData(project, allLabels, dataInfos);
  }
}
