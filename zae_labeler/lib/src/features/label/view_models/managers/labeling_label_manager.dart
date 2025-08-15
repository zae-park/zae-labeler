import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/features/data/models/data_with_status.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';

import '../label_view_model.dart';
import '../../../../core/models/project/project_model.dart';

/// 🏷️ LabelingLabelManager
/// - LabelViewModel 생성 및 캐싱
/// - 라벨 불러오기 및 상태 평가
/// - 리소스 해제 및 상태 유지
class LabelingLabelManager {
  final Project project;
  final AppUseCases appUseCases;

  final Map<String, LabelViewModel> _labelCache = {};
  LabelViewModel? _current;

  /// 외부 위젯에서 상태 변화 감지를 위해 등록
  final VoidCallback? onNotify;

  LabelingLabelManager({required this.project, required this.appUseCases, this.onNotify});

  /// 현재 선택된 데이터에 대응하는 LabelViewModel
  LabelViewModel? get currentLabelVM => _current;

  /// 데이터에 대응하는 라벨을 로드하거나 생성 (cache 유지)
  Future<void> loadLabelFor(DataWithStatus dws) async {
    final id = dws.data.dataId;

    _current = _labelCache.putIfAbsent(id, () {
      final vm = LabelViewModelFactory.create(
        projectId: project.id,
        dataId: dws.data.dataId,
        dataFilename: dws.data.fileName,
        dataPath: dws.data.dataInfo.filePath ?? '',
        mode: project.mode,
        labelUseCases: appUseCases.label,
      );
      if (onNotify != null) vm.addListener(onNotify!);
      return vm;
    });

    await _current!.loadLabel();
  }

  /// 해당 데이터에 대한 라벨 상태를 갱신하고, 콜백으로 전달
  Future refreshStatusFor(DataWithStatus dws, void Function(LabelStatus) onStatusEvaluated) async {
    // 현재 current VM을 보존
    final previousCurrent = _current;

    // 대상 데이터의 VM을 캐시에서 가져오거나 새로 생성
    final vm = getOrCreateLabelVM(dataId: dws.data.dataId, filename: dws.data.fileName, path: dws.data.dataInfo.filePath ?? '', mode: project.mode);

    // 해당 데이터의 라벨 로드
    await vm.loadLabel();

    // 상태 계산
    final status = appUseCases.label.validation.getStatus(project, vm.labelModel);
    onStatusEvaluated(status);

    // current VM을 원래대로 복원
    _current = previousCurrent;
  }

  /// 현재 라벨 저장
  Future<void> saveCurrentLabel() async {
    if (_current != null) {
      await _current!.saveLabel();
    }
  }

  /// 현재 라벨 상태를 평가
  LabelStatus? get currentStatus {
    if (_current == null) return null;
    return appUseCases.label.validation.getStatus(project, _current!.labelModel);
  }

  /// 캐시된 모든 라벨 모델 반환 (내보내기 등에 사용)
  List<LabelModel> get allLabelModels => _labelCache.values.map((vm) => vm.labelModel).toList();

  /// 모든 VM 제거 및 리스너 정리
  Future<void> disposeAll() async {
    for (final vm in _labelCache.values) {
      if (onNotify != null) vm.removeListener(onNotify!);
      vm.dispose();
    }
    _labelCache.clear();
  }

  LabelViewModel getOrCreateLabelVM({required String dataId, required String filename, required String path, required LabelingMode mode}) {
    return _labelCache.putIfAbsent(dataId, () {
      final vm = LabelViewModelFactory.create(
          projectId: project.id, dataId: dataId, dataFilename: filename, dataPath: path, mode: mode, labelUseCases: appUseCases.label);
      vm.addListener(() {});
      return vm;
    });
  }
}
