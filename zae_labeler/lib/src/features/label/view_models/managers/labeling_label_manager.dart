// lib/src/features/label/view_models/managers/labeling_label_manager.dart
import 'package:flutter/foundation.dart';

import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';

import '../../../../core/models/label/label_model.dart' show LabelModel, LabelStatus;
import '../label_view_model.dart';

/// 🏷️ LabelingLabelManager
/// - 데이터(파일)에 대응되는 LabelViewModel을 생성/캐싱
/// - 단일 라벨 로드/저장
/// - 상태(LabelStatus) 평가는 UseCase(LabelUseCases)에 위임
///
/// 주의:
/// - CrossClassification의 경우 `UnifiedData`가 "쌍(pair)" 정보를 포함해야 하며,
///   해당 모드의 ViewModel은 그 컨벤션에 따라 동작합니다.
class LabelingLabelManager {
  final Project project;
  final AppUseCases appUseCases;

  final Map<String, LabelViewModel> _labelCache = {};
  LabelViewModel? _current;

  /// 외부 위젯에서 상태 변화 감지를 위해 등록(옵션)
  final VoidCallback? onNotify;

  LabelingLabelManager({required this.project, required this.appUseCases, this.onNotify});

  /// 현재 선택된 데이터의 LabelViewModel
  LabelViewModel? get currentLabelVM => _current;

  /// 데이터에 대응하는 라벨을 로드(없으면 생성 후 로드)
  Future<void> loadLabelFor(UnifiedData data) async {
    _current = _labelCache.putIfAbsent(data.dataId, () {
      final vm = LabelViewModelFactory.create(project: project, data: data, labelUseCases: appUseCases.label);
      if (onNotify != null) vm.addListener(onNotify!);
      return vm;
    });

    await _current!.loadLabel();
  }

  /// 해당 데이터 라벨의 상태를 일시 평가(캐시는 유지)
  Future<void> refreshStatusFor(
    UnifiedData data,
    void Function(LabelStatus) onStatusEvaluated,
  ) async {
    // 현재 selection 보존
    final prev = _current;

    final vm = getOrCreateLabelVM(data);
    await vm.loadLabel();

    final status = appUseCases.label.statusOf(project, vm.labelModel);
    onStatusEvaluated(status);

    // selection 복원
    _current = prev;
  }

  /// 현재 라벨 저장
  Future<void> saveCurrentLabel() async {
    final vm = _current;
    if (vm != null) {
      await vm.saveLabel();
    }
  }

  /// 현재 라벨 상태 평가(없으면 null)
  LabelStatus? get currentStatus {
    final vm = _current;
    if (vm == null) return null;
    return appUseCases.label.statusOf(project, vm.labelModel);
  }

  /// 캐시된 모든 라벨 모델(내보내기 등에 사용)
  List<LabelModel> get allLabelModels => _labelCache.values.map((vm) => vm.labelModel).toList(growable: false);

  /// VM 캐시 정리
  Future<void> disposeAll() async {
    for (final vm in _labelCache.values) {
      if (onNotify != null) vm.removeListener(onNotify!);
      vm.dispose();
    }
    _labelCache.clear();
    _current = null;
  }

  /// 캐시에서 가져오거나 새로 생성
  LabelViewModel getOrCreateLabelVM(UnifiedData data) {
    return _labelCache.putIfAbsent(data.dataId, () {
      final vm = LabelViewModelFactory.create(project: project, data: data, labelUseCases: appUseCases.label);
      if (onNotify != null) vm.addListener(onNotify!);
      return vm;
    });
  }
}
