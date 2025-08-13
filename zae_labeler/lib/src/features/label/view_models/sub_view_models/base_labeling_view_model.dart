// 📁 sub_view_models/base_labeling_view_model.dart
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/label/logic/labeling_status_manager.dart';
import 'package:zae_labeler/src/features/label/view_models/managers/labeling_data_manager.dart';
import 'package:zae_labeler/src/features/label/view_models/managers/labeling_label_manager.dart';

import '../../../../core/use_cases/app_use_cases.dart';
import '../../models/label_model.dart';
import '../../../../core/models/project/project_model.dart';
import '../../../../core/models/data/data_model.dart';
import '../../../../platform_helpers/storage/interface_storage_helper.dart';
import '../label_view_model.dart';

/// Abstract base class for all LabelingViewModels.
abstract class LabelingViewModel extends ChangeNotifier {
  late Project _project;
  final AppUseCases appUseCases;
  final StorageHelperInterface storageHelper;
  final List<UnifiedData>? initialDataList;

  late final LabelingDataManager _dataManager;
  late final LabelingLabelManager _labelManager;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LabelingViewModel({required Project project, required this.appUseCases, required this.storageHelper, this.initialDataList}) {
    _project = project;
    _dataManager = LabelingDataManager(project: _project, storageHelper: storageHelper, initialDataList: initialDataList);
    _labelManager = LabelingLabelManager(project: _project, appUseCases: appUseCases, onNotify: notifyListeners);
  }

  Project get project => _project;

  set project(Project updated) {
    _project = updated;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _dataManager.load();
    await _labelManager.loadLabelFor(_dataManager.currentData);

    notifyListeners();

    await _validateLabelModelType();
    await refreshAllStatuses();
    await postInitialize();

    _isInitialized = true;
    notifyListeners(); // ✅ 전체 초기화 완료 알림
  }

  Future<void> postInitialize() async {}
  Future<void> postMove() async {}

  Future<void> moveNext() async {
    _dataManager.moveNext();
    await _labelManager.loadLabelFor(_dataManager.currentData);
    await refreshStatus();
    await postMove();
    notifyListeners();
  }

  Future<void> movePrevious() async {
    _dataManager.movePrevious();
    await _labelManager.loadLabelFor(_dataManager.currentData);
    await refreshStatus();
    await postMove();
    notifyListeners();
  }

  /// LabelViewModel 타입 일치 검증
  Future<void> _validateLabelModelType() async {
    final vm = _labelManager.currentLabelVM;
    if (vm == null) return;

    final expectedType = LabelModelFactory.expectedType(project.mode);
    if (vm.labelModel.runtimeType != expectedType) {
      final data = _dataManager.currentData;
      final refreshed = LabelViewModelFactory.create(
        projectId: project.id,
        dataId: data.dataId,
        dataFilename: data.fileName,
        dataPath: data.dataPath ?? '',
        mode: project.mode,
        labelUseCases: appUseCases.label,
      );
      await refreshed.loadLabel();

      _labelManager.disposeAll();
      _labelManager.loadLabelFor(data); // reattach new VM
    }
  }

  /// 라벨 상태 갱신
  Future<void> refreshStatus() async {
    final data = _dataManager.currentData;
    await _labelManager.refreshStatusFor(data, (status) {
      _dataManager.updateStatus(data.dataId, status);
    });
  }

  /// 전체 라벨 상태 갱신
  Future refreshAllStatuses() async {
    final statusMgr = StatusManager(project: project, useCases: appUseCases.label);
    final vmMap = {
      for (var data in dataManager.allData)
        data.dataId: labelManager.getOrCreateLabelVM(dataId: data.dataId, filename: data.fileName, path: data.dataPath ?? '', mode: project.mode)
    };
    final statuses = await statusMgr.refreshAll(dataManager.allData, vmMap);
    statuses.forEach((id, status) {
      dataManager.updateStatus(id, status);
    });
    notifyListeners();
  }
  // =============================
  // 📌 Interface
  // =============================

  @protected
  LabelingDataManager get dataManager => _dataManager;

  @protected
  LabelingLabelManager get labelManager => _labelManager;

  UnifiedData get currentUnifiedData => _dataManager.currentData;
  int get currentIndex => _dataManager.currentIndex;
  List<UnifiedData> get unifiedDataList => _dataManager.allData;

  LabelViewModel get currentLabelVM => _labelManager.currentLabelVM!;
  int get totalCount => _dataManager.totalCount;
  int get completeCount => _dataManager.completeCount;
  int get warningCount => _dataManager.warningCount;
  int get incompleteCount => _dataManager.incompleteCount;
  double get progressRatio => _dataManager.progressRatio;

  String get currentDataFileName => currentUnifiedData.fileName;
  List<double>? get currentSeriesData => currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => currentUnifiedData.objectData;

  // abstract labeling control
  Future<void> updateLabel(dynamic labelData);
  void toggleLabel(String labelItem) => throw UnimplementedError();
  bool isLabelSelected(String labelItem) => throw UnimplementedError();

  Future<String> exportAllLabels() async {
    final labelModels = _labelManager.allLabelModels;
    final dataInfos = unifiedDataList.map((e) => e.toDataInfo()).toList();
    return await appUseCases.label.io.exportLabelsWithData(project, labelModels, dataInfos);
  }

  @override
  void dispose() {
    _labelManager.disposeAll();
    super.dispose();
  }
}
