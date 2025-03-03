// lib/src/view_models/labeling_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/label_models/classification_label_model.dart';
import '../models/label_model.dart';
import '../models/label_models/segmentation_label_model.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';

class LabelingViewModel extends ChangeNotifier {
  // 멤버 변수 선언
  final Project project;
  final StorageHelperInterface storageHelper; // ✅ Dependency Injection 허용

  bool _isInitialized = false;
  final bool _memoryOptimized = true;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  final Set<String> selectedLabels = {};
  Map<String, LabelEntry> _labelEntryCache = {}; // ✅ 캐싱 추가

  // Getter & Setter
  bool get isInitialized => _isInitialized;

  int get currentIndex => _currentIndex;
  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;

  String get currentDataFileName => currentUnifiedData.fileName;
  List<double>? get currentSeriesData => _currentUnifiedData.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData.objectData;
  File? get currentImageFile => _currentUnifiedData.file;

  List<LabelEntry> get labelEntries => project.labelEntries;

  // Factory 생성자
  Future<void> moveNext() async => _move(1);
  Future<void> movePrevious() async => _move(-1);

  // 인스턴스 생성
  LabelingViewModel({required this.project, required this.storageHelper});

  Future<void> initialize() async {
    if (project.labelEntries.isEmpty) {
      project.labelEntries = await project.loadLabelEntries();
    }

    // ✅ 캐싱 초기화
    _labelEntryCache = {for (var entry in project.labelEntries) entry.dataFilename: entry};

    // ✅ 데이터 로딩 최적화
    if (_memoryOptimized) {
      _unifiedDataList.clear();
      _currentUnifiedData = project.dataPaths.isNotEmpty ? await UnifiedData.fromDataPath(project.dataPaths.first) : UnifiedData.empty();
    } else {
      _unifiedDataList = await Future.wait(project.dataPaths.map((dpath) => UnifiedData.fromDataPath(dpath)));
      _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    }

    _isInitialized = true; // ✅ 초기화 완료
    notifyListeners();
  }

  LabelEntry get currentLabelEntry {
    final dataFilename = currentUnifiedData.fileName; // ✅ 현재 파일 기반으로 검색
    return project.labelEntries.firstWhere((entry) => entry.dataFilename == dataFilename, orElse: () => LabelEntry.empty(project.mode));
  }

  /// ✅ 현재 파일의 `LabelEntry`를 가져오거나 생성
  LabelEntry getOrCreateLabelEntry() {
    final dataFilename = currentUnifiedData.fileName;

    if (_labelEntryCache.containsKey(dataFilename)) {
      return _labelEntryCache[dataFilename]!;
    }

    final dataPath = project.dataPaths.firstWhere((dp) => dp.fileName == dataFilename).filePath ?? '';
    LabelEntry<LabelModel> newEntry = LabelEntry<LabelModel>(
      dataFilename: dataFilename,
      dataPath: dataPath,
      labelingMode: project.mode,
      labelData: LabelModel.empty(),
    );
    project.labelEntries.add(newEntry);
    _labelEntryCache[dataFilename] = newEntry;
    return newEntry;
  }

  Future<void> loadCurrentData() async {
    // ✅ 이름 변경
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;

    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);

    notifyListeners();
  }

  Future<void> addOrUpdateLabel(String label, LabelingMode mode) async {
    final entry = getOrCreateLabelEntry();

    // ✅ Label 업데이트 로직 간결화
    final updatedLabel = _updateLabel(entry, label);
    if (updatedLabel) {
      notifyListeners();
      await storageHelper.saveLabelEntry(project.id, entry);
    }
  }

  /// ✅ `LabelingMode`에 따라 `labelData`를 업데이트하는 함수
  bool _updateLabel(LabelEntry<LabelModel> entry, String label) {
    if (entry.labelData is SegmentationLabel) {
      final segmentationLabel = entry.labelData as SegmentationLabel;
      final List<int> sampleIndices = [10, 20, 30]; // ✅ 예제 인덱스

      List<Segment> updatedSegments = List.from(segmentationLabel.label.segments); // ✅ label로 변경
      if (!updatedSegments.any((s) => s.indices == sampleIndices)) {
        updatedSegments.add(Segment(indices: sampleIndices, classLabel: label));
      }

      LabelEntry<LabelModel> updatedEntry = entry.copyWith(
        labelData: segmentationLabel.copyWith(label: SegmentationData(segments: updatedSegments)), // ✅ label로 변경
      );

      _labelEntryCache[entry.dataFilename] = updatedEntry;
      project.labelEntries[project.labelEntries.indexWhere((e) => e.dataFilename == entry.dataFilename)] = updatedEntry;
      return true;
    }

    return false;
  }

  /// ✅ `LabelingMode`에 따라 라벨이 선택되었는지 확인하는 함수
  bool isLabelSelected(String label, LabelingMode mode) {
    final entry = getOrCreateLabelEntry();

    final labelCheckers = {
      LabelingMode.singleClassification: () => (entry.labelData as SingleClassificationLabel?)?.label == label,
      LabelingMode.multiClassification: () => (entry.labelData as MultiClassificationLabel?)?.labels.contains(label) ?? false,
    };

    return labelCheckers[mode]?.call() ?? false;
  }

  void toggleLabel(String label, LabelingMode mode) {
    isLabelSelected(label, mode) ? selectedLabels.remove(label) : selectedLabels.add(label);
    notifyListeners();
  }

  Future<void> _move(int delta) async {
    int newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < project.dataPaths.length) {
      _currentIndex = newIndex;
      await loadCurrentData();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await storageHelper.downloadLabelsAsZip(project, project.labelEntries, []);
  }
}
