import 'package:flutter/material.dart';

import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../label_view_model.dart';

abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelperInterface storageHelper;

  bool _isInitialized = false;
  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Map<String, LabelViewModel> _labelCache = {};

  LabelingViewModel({required this.project, required this.storageHelper});

  bool get isInitialized => _isInitialized;
  int get currentIndex => _currentIndex;
  UnifiedData get currentUnifiedData => _currentUnifiedData;
  LabelViewModel get currentLabelVM => getOrCreateLabelVM();

  Future<void> initialize() async {
    _unifiedDataList = await Future.wait(project.dataPaths.map((d) => UnifiedData.fromDataPath(d)));
    _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    await getOrCreateLabelVM().loadLabel();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  Future<void> updateLabel(dynamic labelData);

  Future<String> exportAllLabels() async {
    final allLabels = _labelCache.values.map((vm) => vm.labelModel).toList();
    return await storageHelper.exportAllLabels(project, allLabels, project.dataPaths);
  }

  Future<void> _move(int delta) async {
    int newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
      await getOrCreateLabelVM().loadLabel();
      notifyListeners();
    }
  }

  LabelViewModel getOrCreateLabelVM() {
    final id = _currentUnifiedData.dataId;
    return _labelCache.putIfAbsent(id, () {
      return LabelViewModel(
        projectId: project.id,
        dataId: id,
        dataFilename: _currentUnifiedData.fileName,
        dataPath: _currentUnifiedData.file?.path ?? '',
        mode: project.mode,
        labelModel: LabelModelFactory.createNew(project.mode),
      );
    });
  }
}
