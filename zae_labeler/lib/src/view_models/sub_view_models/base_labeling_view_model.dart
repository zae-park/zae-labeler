// 📁 sub_view_models/base_labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/label_model.dart';
import '../../utils/label_validator.dart';
import '../label_view_model.dart';
import '../../models/data_model.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';

abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;

  bool _isInitialized = false;
  final bool _memoryOptimized = false;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Map<String, LabelViewModel> _labelCache = {};

  // ✅ 생성자
  LabelingViewModel({required this.project, required this.storageHelper});

  // ✅ 상태 getter들
  bool get isInitialized => _isInitialized;
  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  String get currentDataFileName => _currentUnifiedData.fileName;
  File? get currentImageFile => _currentUnifiedData.file;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;

  // ✅ 진행률 계산
  int get totalCount => unifiedDataList.length;
  int get completeCount => unifiedDataList.where((e) => e.status == LabelStatus.complete).length;
  int get warningCount => unifiedDataList.where((e) => e.status == LabelStatus.warning).length;
  int get incompleteCount => unifiedDataList.where((e) => e.status == LabelStatus.incomplete).length;
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  // ✅ 초기화
  Future<void> initialize() async {
    debugPrint("[LabelingVM.initialize] : ${project.mode}");
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

  // ✅ 전환 시 라벨 상태 새로고침
  Future<void> postInitialize() async {}
  Future<void> postMove() async {}

  // ✅ 라벨 타입 불일치 시 자동 초기화
  Future<void> validateLabelModelType() async {
    final labelVM = currentLabelVM;
    final expected = LabelModelFactory.createNew(project.mode);
    if (labelVM.labelModel.runtimeType != expected.runtimeType) {
      debugPrint("⚠️ 라벨 모델 타입 불일치 → 초기화");
      labelVM.labelModel = expected;
      await labelVM.saveLabel();
    }
  }

  // ✅ 이동
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

  // ✅ 라벨 VM 캐싱
  LabelViewModel getOrCreateLabelVM() {
    final id = _currentUnifiedData.dataId;
    return _labelCache.putIfAbsent(id, () {
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

  // ✅ 라벨 상태 업데이트
  Future<void> refreshStatus(String dataId) async {
    final vm = getOrCreateLabelVM();
    final status = LabelValidator.getStatus(project, vm.labelModel);
    final index = unifiedDataList.indexWhere((e) => e.dataId == dataId);
    if (index != -1) {
      unifiedDataList[index] = unifiedDataList[index].copyWith(status: status);
    }
  }

  // ✅ 전체 상태 새로고침
  Future<void> refreshAllStatuses() async {
    for (final data in unifiedDataList) {
      final vm = getOrCreateLabelVM();
      await vm.loadLabel();
      final status = LabelValidator.getStatus(project, vm.labelModel);
      final idx = unifiedDataList.indexWhere((e) => e.dataId == data.dataId);
      if (idx != -1) {
        unifiedDataList[idx] = unifiedDataList[idx].copyWith(status: status);
      }
    }
  }

  // ✅ override 필요
  Future<void> updateLabel(dynamic labelData);
  void toggleLabel(String labelItem) => throw UnimplementedError();
  bool isLabelSelected(String labelItem) => throw UnimplementedError();

  // ✅ export
  Future<String> exportAllLabels() async {
    final allLabels = _labelCache.values.map((vm) => vm.labelModel).toList();
    return await storageHelper.exportAllLabels(project, allLabels, project.dataPaths);
  }
}
