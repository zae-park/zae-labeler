// 📁 sub_view_models/base_labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';

import '../../models/label_model.dart';
import '../label_view_model.dart';
import '../../models/data_model.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';

abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;

  bool _isInitialized = false;
  final bool _memoryOptimized = true;

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

  String get currentDataFileName => _currentUnifiedData.fileName;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;
  File? get currentImageFile => _currentUnifiedData.file;

  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  // ✅ 공통 초기화 메서드
  Future<void> initialize() async {
    if (_memoryOptimized) {
      _unifiedDataList.clear();
      _currentUnifiedData = project.dataPaths.isNotEmpty ? await UnifiedData.fromDataPath(project.dataPaths.first) : UnifiedData.empty();
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map(UnifiedData.fromDataPath));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }
    await getOrCreateLabelVM().loadLabel();
    await validateLabelModelType();
    _isInitialized = true;
    notifyListeners();
  }

  // ✅ 공통 Label 모델 일치 확인
  Future<void> validateLabelModelType() async {
    final labelVM = currentLabelVM;

    final expected = LabelModelFactory.createNew(project.mode);
    final expectedType = expected.runtimeType;
    final actualType = labelVM.labelModel.runtimeType;

    if (expectedType != actualType) {
      print("⚠️ 라벨 모델 타입 불일치: 현재=$actualType, 기대=$expectedType → 초기화 수행");

      labelVM.labelModel = expected;
      await labelVM.saveLabel();
    }
  }

  // ✅ 공통 이동
  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  Future<void> _move(int delta) async {
    final newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
      await getOrCreateLabelVM().loadLabel();
      notifyListeners();
    }
  }

  // ✅ 라벨 캐싱
  LabelViewModel getOrCreateLabelVM() {
    final id = _currentUnifiedData.dataId;

    return _labelCache.putIfAbsent(id, () {
      return LabelViewModelFactory.create(
        projectId: project.id,
        dataId: id,
        dataFilename: _currentUnifiedData.fileName,
        dataPath: _currentUnifiedData.file?.path ?? '',
        mode: project.mode,
      );
    });
  }

  // ✅ 라벨 업데이트 (구현체에서 구체적 정의)
  Future<void> updateLabel(dynamic labelData);

  // ✅ 라벨 일괄 export
  Future<String> exportAllLabels() async {
    final allLabels = _labelCache.values.map((vm) => vm.labelModel).toList();
    return await storageHelper.exportAllLabels(project, allLabels, project.dataPaths);
  }

  void toggleLabel(String labelItem) {
    throw UnimplementedError("toggleLabel is only supported in classification mode");
  }

  bool isLabelSelected(String labelItem) {
    throw UnimplementedError("isLabelSelected is only supported in classification mode");
  }
}
