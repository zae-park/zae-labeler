// lib/src/features/label/use_cases/label_use_cases.dart
import 'package:collection/collection.dart' show IterableExtension;

import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/features/data/models/data_with_status.dart';
import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';
import 'package:zae_labeler/src/features/label/models/sub_models/classification_label_model.dart';

import '../models/label_model.dart';
import '../repository/label_repository.dart';
import 'validate_label_use_case.dart';
import 'labeling_summary_use_case.dart';
import 'label_io_use_case.dart';

class LabelUseCases {
  final LabelRepository repository;
  final LabelValidationUseCase validation;
  final LabelingSummaryUseCase summary;
  final LabelIOUseCase io;

  final AdaptiveUnifiedDataLoader adaptiveLoader; // 데이터+상태 일괄 로딩용
  final UnifiedDataService uds; // 단건 데이터 로딩용

  LabelUseCases({
    required this.repository,
    LabelValidationUseCase? validation,
    LabelingSummaryUseCase? summary,
    LabelIOUseCase? io,
    AdaptiveUnifiedDataLoader? loader,
    UnifiedDataService? uds,
  })  : validation = validation ?? LabelValidationUseCase(repository: repository),
        summary = summary ?? LabelingSummaryUseCase(repository: repository, validUseCase: LabelValidationUseCase(repository: repository)),
        io = io ?? LabelIOUseCase(repository: repository),
        adaptiveLoader = loader ?? AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: repository.storageHelper),
        uds = uds ?? UnifiedDataService();

  // =========================
  //           Query
  // =========================

  /// 프로젝트의 모든 데이터 + 상태 로딩 (플랫폼 적응형)
  Future<List<DataWithStatus>> loadItems(Project project) async {
    return adaptiveLoader.load(project); // 내부에서 라벨맵·상태 계산까지 수행
  }

  /// 단일 데이터 + 상태 로딩
  Future<DataWithStatus?> loadItem(Project project, String dataId) async {
    final info = _resolve(project, dataId);
    if (info == null) return null;

    // 데이터(파일/베이스64 등) 파싱
    final data = await uds.fromDataInfo(info);

    // 현재 저장된 라벨(있으면) 로드
    LabelModel? label;
    try {
      label = await repository.loadLabel(
        projectId: project.id,
        dataId: dataId,
        dataPath: info.filePath ?? info.fileName, // 웹이면 파일명으로 대체
        mode: project.mode,
      ); // 없으면 스토리지가 throw 할 수 있음
    } catch (_) {
      label = null;
    }

    final status = repository.getStatus(project, label); // 완료/주의/미완료
    return DataWithStatus(data: data, status: status);
  }

  /// 진행 요약(총계/완료/주의/미완료)
  Future<LabelingSummary> getProgress(Project project) => summary.load(project);

  /// 단일 라벨(있으면) 조회
  Future<LabelModel?> getLabel(Project project, String dataId) async {
    final info = _resolve(project, dataId);
    if (info == null) return null;
    try {
      return await repository.loadLabel(
        projectId: project.id,
        dataId: dataId,
        dataPath: info.filePath ?? info.fileName,
        mode: project.mode,
      );
    } catch (_) {
      return null; // 없으면 null
    }
  }

  // =========================
  //          Command
  // =========================

  /// 단일 업서트
  Future<LabelModel?> upsert({
    required Project project,
    required String dataId,
    required Object value, // single: String, multi: List<String>, ...
  }) async {
    final info = _resolve(project, dataId);
    if (info == null) return null;

    final model = _buildLabel(project.mode, dataId, value);
    await repository.saveLabel(
      projectId: project.id,
      dataId: dataId,
      dataPath: info.filePath ?? info.fileName,
      labelModel: model,
    );
    return model;
  }

  /// 단건 삭제 (레포에 전용 API 없으면 fallback)
  Future<void> remove({required Project project, required String dataId}) async {
    // fallback: 전체 로드 → 필터 → saveAll
    final all = await repository.loadAllLabels(project.id);
    final filtered = all.where((e) => e.dataId != dataId).toList();
    await repository.saveAllLabels(project.id, filtered);
  }

  /// 전체 삭제
  Future<void> clearAll(Project project) => repository.deleteAllLabels(project.id);

  /// 배치 업서트 (성공/스킵/에러 요약)
  Future<BatchResult> batchUpsert({
    required Project project,
    required Map<String, Object> entries, // dataId -> value
    bool skipUnknown = true,
  }) async {
    final ids = project.dataInfos.map((e) => e.id).toSet();
    final toSave = <LabelModel>[];
    final skipped = <String>[];
    final errors = <String, String>{};

    for (final entry in entries.entries) {
      final dataId = entry.key;
      final value = entry.value;

      if (skipUnknown && !ids.contains(dataId)) {
        skipped.add(dataId);
        continue;
      }

      try {
        toSave.add(_buildLabel(project.mode, dataId, value));
      } catch (e) {
        errors[dataId] = e.toString();
      }
    }

    if (toSave.isNotEmpty) {
      await repository.saveAllLabels(project.id, toSave);
    }

    return BatchResult(
      saved: toSave.length,
      skipped: skipped,
      errors: errors,
      total: entries.length,
    );
  }

  /// 배치 삭제
  Future<BatchResult> batchRemove({
    required Project project,
    required List<String> dataIds,
  }) async {
    // fallback 구현: 전체 로드 → 필터 → saveAll
    final all = await repository.loadAllLabels(project.id);
    final set = dataIds.toSet();
    final filtered = all.where((e) => !set.contains(e.dataId)).toList();

    final removed = all.length - filtered.length;
    await repository.saveAllLabels(project.id, filtered);

    return BatchResult(saved: removed, skipped: const [], errors: const {}, total: dataIds.length);
  }

  // =========================
  //             IO
  // =========================

  Future<String> exportJson(Project project) async {
    final labels = await repository.loadAllLabels(project.id);
    return io.exportLabels(project, labels);
  }

  Future<String> exportWithData(Project project) async {
    final labels = await repository.loadAllLabels(project.id);
    return io.exportLabelsWithData(project, labels, project.dataInfos);
  }

  Future<List<LabelModel>> importFromPicker() => io.importLabels();

  // =========================
  //           helpers
  // =========================

  DataInfo? _resolve(Project project, String dataId) => project.dataInfos.firstWhereOrNull((e) => e.id == dataId);

  LabelModel _buildLabel(LabelingMode mode, String dataId, Object value) {
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel(dataId: dataId, label: value as String);
      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel(dataId: dataId, label: (value as List).cast<String>());
      case LabelingMode.segmentation:
        throw UnimplementedError('Segmentation labeling is not implemented yet.');
    }
  }
}

class BatchResult {
  final int saved;
  final List<String> skipped;
  final Map<String, String> errors;
  final int total;

  const BatchResult({
    required this.saved,
    required this.skipped,
    required this.errors,
    required this.total,
  });

  int get failed => errors.length;
}
