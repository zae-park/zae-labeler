import 'package:zae_labeler/src/core/models/data_model.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';

import '../label_view_model.dart';
import '../../../project/models/project_model.dart';

/// 🏷️ LabelManager
/// - LabelViewModel의 생성, 캐싱, 라벨 저장 및 불러오기 담당.
/// - 라벨 캐시를 유지하고 데이터 단위로 라벨을 관리함.
///
/// 주요 책임:
/// - getOrCreateLabelVM
/// - saveLabel, loadLabel
/// - toggle, update
class LabelingLabelManager {
  final Project project;
  final AppUseCases appUseCases;

  final Map<String, LabelViewModel> _labelCache = {};
  LabelViewModel? _current;

  LabelingLabelManager({
    required this.project,
    required this.appUseCases,
  });

  LabelViewModel? get currentLabelVM => _current;

  Future<void> loadLabelFor(UnifiedData data) async {
    final id = data.dataId;

    _current = _labelCache.putIfAbsent(id, () {
      final vm = LabelViewModelFactory.create(
        projectId: project.id,
        dataId: data.dataId,
        dataFilename: data.fileName,
        dataPath: data.dataPath ?? '',
        mode: project.mode,
        labelUseCases: appUseCases.label,
      );
      vm.addListener(() {});
      return vm;
    });

    await _current!.loadLabel();
  }

  Future<void> refreshStatusFor(UnifiedData data, Function(LabelStatus) onStatusEvaluated) async {
    await loadLabelFor(data);
    final status = appUseCases.label.validation.getStatus(project, _current!.labelModel);
    onStatusEvaluated(status);
  }

  Future<void> disposeAll() async {
    for (final vm in _labelCache.values) {
      vm.removeListener(() {});
      vm.dispose();
    }
    _labelCache.clear();
  }
}
