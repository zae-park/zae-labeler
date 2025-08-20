// lib/src/features/label/view_models/managers/labeling_label_manager.dart
import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';

import '../../../../core/models/project/project_model.dart';
import '../../models/label_model.dart' show LabelModel, LabelStatus, LabelingMode;
import '../label_view_model.dart';

/// 🏷️ LabelingLabelManager
/// - 데이터(파일)에 대응되는 LabelViewModel을 생성/캐싱
/// - 단일 라벨 로드/저장
/// - 필요 시 상태(LabelStatus) 평가(검증은 UseCase에 위임)
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
    final id = data.dataId;

    _current = _labelCache.putIfAbsent(id, () {
      final vm = LabelViewModelFactory.create(
        projectId: project.id,
        dataId: data.dataId,
        dataFilename: data.fileName,
        dataPath: data.dataInfo.filePath ?? '',
        mode: project.mode,
        labelUseCases: appUseCases.label,
      );
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

    final vm = getOrCreateLabelVM(dataId: data.dataId, filename: data.fileName, path: data.dataInfo.filePath ?? '', mode: project.mode);
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
  LabelViewModel getOrCreateLabelVM({required String dataId, required String filename, required String path, required LabelingMode mode}) {
    return _labelCache.putIfAbsent(dataId, () {
      final vm = LabelViewModelFactory.create(
        projectId: project.id,
        dataId: dataId,
        dataFilename: filename,
        dataPath: path,
        mode: mode,
        labelUseCases: appUseCases.label,
      );
      if (onNotify != null) vm.addListener(onNotify!);
      return vm;
    });
  }
}
