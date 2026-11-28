// test/features/label/cross_summary_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/label/repository/label_repository.dart';
import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart';
import 'package:zae_labeler/src/features/label/view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/labeling_data_manager.dart';
import 'package:zae_labeler/src/features/project/repository/project_repository.dart';
import 'package:zae_labeler/src/utils/label_validator.dart';

import '../../support/in_memory_storage_helper.dart';

CrossClassificationLabelModel _rel(String s, String t, String relation) => CrossClassificationLabelModel(
  dataId: CrossDataPair.idFor(s, t),
  label: CrossDataPair(sourceId: s, targetId: t, relation: relation),
  labeledAt: DateTime(2025),
);

void main() {
  // 데이터 4개 → 4C2 = 6쌍
  final project = Project(
    id: 'cross',
    name: 'Cross',
    mode: LabelingMode.crossClassification,
    classes: const ['same', 'diff'],
    dataInfos: [
      for (final id in ['a', 'b', 'c', 'd']) DataInfo(id: id, fileName: '$id.csv'),
    ],
  );

  late InMemoryStorageHelper storage;
  late LabelUseCases useCases;

  setUp(() {
    storage = InMemoryStorageHelper()
      ..projects = [project]
      ..seed(project.id, [
        _rel('a', 'b', 'same'),
        _rel('a', 'c', 'diff'),
        _rel('b', 'd', 'removed-class'), // 클래스 목록에서 빠진 relation → 경고
        _rel('c', 'd', ''), // 해제된 쌍 → 미완료
      ]);
    useCases = LabelUseCases.from(LabelRepository(storageHelper: storage), ProjectRepository(storageHelper: storage));
  });

  test('CrossDataPair.pairId 규칙', () {
    expect(const CrossDataPair(sourceId: 'a', targetId: 'b').pairId, 'a_b');
    expect(CrossDataPair.idFor('x', 'y'), 'x_y');
  });

  test('검증기: 프로젝트 클래스에 있는 relation만 유효하다', () {
    expect(LabelValidator.getStatus(project, _rel('a', 'b', 'same')), LabelStatus.complete);
    expect(LabelValidator.getStatus(project, _rel('a', 'b', 'removed-class')), LabelStatus.warning);
    expect(LabelValidator.getStatus(project, _rel('a', 'b', '')), LabelStatus.incomplete);
  });

  test('목록 요약은 교차 분류를 데이터가 아니라 쌍 단위로 계산한다', () async {
    final summary = await useCases.computeSummary(project.id);

    expect(summary.total, 6);
    expect(summary.complete, 2);
    expect(summary.warning, 1);
    expect(summary.incomplete, 4);
    expect(summary.progress, closeTo(2 / 6, 1e-9));
  });

  test('라벨링 화면 VM과 목록 요약의 진행률이 일치한다', () async {
    final vm = CrossClassificationLabelingViewModel(
      project: project,
      storageHelper: storage,
      labelUseCases: useCases,
      dataManager: LabelingDataManager(
        project: project,
        storageHelper: storage,
        initialDataList: [
          for (final d in project.dataInfos) UnifiedData(dataInfo: d, fileType: FileType.series, seriesData: const [1]),
        ],
      ),
    );
    await vm.initialize();
    final summary = await useCases.computeSummary(project.id);

    expect(vm.totalCount, summary.total);
    expect(vm.completeCount, summary.complete);
    expect(vm.warningCount, summary.warning);
    expect(vm.progressRatio, closeTo(summary.progress, 1e-9));

    // 화면에서 하나 더 라벨링하면 요약에도 반영된다
    await vm.jumpTo(5); // c_d
    await vm.setRelation('diff');
    expect((await useCases.computeSummary(project.id)).complete, 3);
    expect(vm.completeCount, 3);
    vm.dispose();
  });

  test('일반 모드 요약은 기존처럼 데이터 단위다', () async {
    final single = Project(id: 's', name: 'S', mode: LabelingMode.singleClassification, classes: const ['A'], dataInfos: project.dataInfos);
    storage
      ..projects = [single]
      ..seed('s', [SingleClassificationLabelModel(dataId: 'a', label: 'A', labeledAt: DateTime(2025))]);

    final summary = await useCases.computeSummary('s');
    expect(summary.total, 4);
    expect(summary.complete, 1);
  });
}
