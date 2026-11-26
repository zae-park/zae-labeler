// lib/src/features/label/view_models/classification_labeling_view_model.dart
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';

import 'labeling_view_model.dart';

/// 단일/다중 분류 라벨링 VM.
class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.labelUseCases, super.dataManager});

  bool get isMultiLabel => mode == LabelingMode.multiClassification;

  Set<String> get _currentSet {
    final v = currentLabel?.label;
    return v is Set<String> ? v : <String>{};
  }

  /// 현재 데이터에서 [labelItem]이 선택되어 있는지.
  bool isLabelSelected(String labelItem) {
    final v = currentLabel?.label;
    return isMultiLabel ? _currentSet.contains(labelItem) : v == labelItem;
  }

  /// 클릭 토글: 다중 분류는 집합에서 추가/제거, 단일 분류는 같은 항목을 다시 누르면 해제.
  Future<void> toggleLabel(String labelItem) {
    if (isMultiLabel) {
      final next = Set<String>.from(_currentSet);
      if (!next.remove(labelItem)) next.add(labelItem);
      return applyInput(next);
    }
    return applyInput(isLabelSelected(labelItem) ? null : labelItem);
  }

  /// 숫자 단축키: 단일 분류는 선택(해제하지 않음), 다중 분류는 토글.
  Future<void> applyShortcut(String labelItem) => isMultiLabel ? toggleLabel(labelItem) : applyInput(labelItem);
}

/// 교차(쌍) 분류 라벨링 VM.
///
/// 데이터 n개로 만든 nC2 쌍을 순서대로 탐색하며, 각 쌍의 relation을 `"{source}_{target}"` dataId로 저장합니다.
/// relation은 라벨 맵(단일 소스)에서 바로 읽으므로 별도 복제 상태를 두지 않습니다.
class CrossClassificationLabelingViewModel extends LabelingViewModel {
  CrossClassificationLabelingViewModel({required super.project, required super.storageHelper, required super.labelUseCases, super.dataManager});

  List<CrossDataPair> _pairs = const [];
  int _pairIndex = 0;

  static String pairIdOf(CrossDataPair p) => '${p.sourceId}_${p.targetId}';

  @override
  Future<void> postInitialize() async {
    final ids = dataManager.allData.map((e) => e.dataId).toList(growable: false);
    _pairs = [
      for (int i = 0; i < ids.length - 1; i++)
        for (int j = i + 1; j < ids.length; j++) CrossDataPair(sourceId: ids[i], targetId: ids[j]),
    ];
    _pairIndex = 0;
  }

  List<CrossDataPair> get pairs => _pairs;
  CrossDataPair? get currentPair => _pairs.isEmpty ? null : _pairs[_pairIndex];

  /// 저장된 relation(없으면 빈 문자열).
  String relationOf(CrossDataPair pair) {
    final saved = savedLabelOf(pairIdOf(pair));
    final v = saved?.label;
    return v is CrossDataPair ? v.relation : '';
  }

  UnifiedData _dataById(String id) => dataManager.allData.firstWhere((e) => e.dataId == id);
  UnifiedData get currentSourceData => _dataById(currentPair!.sourceId);
  UnifiedData get currentTargetData => _dataById(currentPair!.targetId);

  bool isLabelSelected(String relation) {
    final p = currentPair;
    return p != null && relationOf(p) == relation;
  }

  /// 현재 쌍의 relation 설정.
  Future<void> setRelation(String relation) async {
    final p = currentPair;
    if (p == null) return;
    final id = pairIdOf(p);
    final model = inputMapper.map(
      p.copyWith(relation: relation),
      dataId: id,
      dataPath: '',
    );
    await commitLabel(id, model);
  }

  /// 같은 relation을 다시 누르면 해제.
  Future<void> toggleLabel(String relation) => setRelation(isLabelSelected(relation) ? '' : relation);

  // ── 쌍 단위 탐색 ──
  @override
  bool get hasNext => _pairIndex < _pairs.length - 1;

  @override
  bool get hasPrevious => _pairIndex > 0;

  @override
  Future<void> moveNext() async {
    if (!hasNext) return;
    _pairIndex++;
    notify();
  }

  @override
  Future<void> movePrevious() async {
    if (!hasPrevious) return;
    _pairIndex--;
    notify();
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _pairs.length) return;
    _pairIndex = index;
    notify();
  }

  // ── 쌍 단위 진행률 ──
  @override
  int get totalCount => _pairs.length;

  @override
  int get currentIndex => _pairIndex;

  @override
  int get completeCount => _pairs.where((p) => relationOf(p).isNotEmpty).length;

  @override
  int get warningCount => 0;

  @override
  String get currentItemName {
    final p = currentPair;
    if (p == null) return '';
    return '${_dataById(p.sourceId).fileName} ↔ ${_dataById(p.targetId).fileName}';
  }
}
