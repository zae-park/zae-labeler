// test/features/label/labeling_view_model_test.dart
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
import 'package:zae_labeler/src/features/label/view_models/segmentation_labeling_view_model.dart';

import '../../support/in_memory_storage_helper.dart';

UnifiedData _series(String id) => UnifiedData(
  dataInfo: DataInfo(id: id, fileName: '$id.csv'),
  fileType: FileType.series,
  seriesData: const [1, 2, 3],
);

Project _project(LabelingMode mode, {List<String> classes = const ['A', 'B'], int dataCount = 3}) => Project(
  id: 'p1',
  name: 'P',
  mode: mode,
  classes: classes,
  dataInfos: [for (int i = 0; i < dataCount; i++) DataInfo(id: 'd$i', fileName: 'd$i.csv')],
);

void main() {
  late InMemoryStorageHelper storage;
  late LabelUseCases useCases;

  setUp(() {
    storage = InMemoryStorageHelper();
    useCases = LabelUseCases.from(LabelRepository(storageHelper: storage), ProjectRepository(storageHelper: storage));
  });

  LabelingDataManager dataFor(Project p) =>
      LabelingDataManager(project: p, storageHelper: storage, initialDataList: [for (final d in p.dataInfos) _series(d.id)]);

  group('ClassificationLabelingViewModel (single)', () {
    late Project project;
    late ClassificationLabelingViewModel vm;

    setUp(() async {
      project = _project(LabelingMode.singleClassification);
      storage.seed(project.id, [SingleClassificationLabelModel(dataId: 'd1', label: 'B', labeledAt: DateTime(2025))]);
      vm = ClassificationLabelingViewModel(project: project, storageHelper: storage, labelUseCases: useCases, dataManager: dataFor(project));
      await vm.initialize();
    });

    tearDown(() => vm.dispose());

    test('초기화 시 라벨을 한 번만 일괄 로드하고 상태를 계산한다', () {
      expect(storage.loadAllCalls, 1);
      expect(storage.loadSingleCalls, 0);
      expect(vm.totalCount, 3);
      expect(vm.completeCount, 1);
      expect(vm.incompleteCount, 2);
      expect(vm.isRenderPending, isFalse);
      expect(vm.currentRenderable(), [1, 2, 3]);
    });

    test('toggleLabel은 1회만 저장하고 진행률을 증분 갱신한다', () async {
      await vm.toggleLabel('A');

      expect(storage.saveLabelCalls, 1);
      expect(storage.loadAllCalls, 1, reason: '라벨 변경 때마다 전체를 다시 읽지 않아야 함');
      expect(vm.isLabelSelected('A'), isTrue);
      expect(vm.completeCount, 2);
      expect(storage.stored(project.id, 'd0')?.label, 'A');
    });

    test('같은 라벨을 다시 토글하면 해제된다', () async {
      await vm.toggleLabel('A');
      await vm.toggleLabel('A');

      expect(vm.isLabelSelected('A'), isFalse);
      expect(vm.completeCount, 1);
      expect(storage.saveLabelCalls, 2);
    });

    test('단축키는 단일 분류에서 해제하지 않고 선택만 한다', () async {
      await vm.applyShortcut('A');
      await vm.applyShortcut('A');
      expect(vm.isLabelSelected('A'), isTrue);
    });

    test('이동하면 다음 데이터의 저장된 라벨이 보인다', () async {
      final notified = <int>[];
      vm.addListener(() => notified.add(vm.currentIndex));

      await vm.moveNext();

      expect(vm.currentIndex, 1);
      expect(vm.isLabelSelected('B'), isTrue);
      expect(notified, isNotEmpty);
      expect(vm.hasPrevious, isTrue);
    });
  });

  group('ClassificationLabelingViewModel (multi)', () {
    test('토글로 집합에 추가/제거한다', () async {
      final project = _project(LabelingMode.multiClassification);
      final vm = ClassificationLabelingViewModel(project: project, storageHelper: storage, labelUseCases: useCases, dataManager: dataFor(project));
      await vm.initialize();

      await vm.toggleLabel('A');
      await vm.toggleLabel('B');
      await vm.toggleLabel('A');

      expect(vm.isLabelSelected('A'), isFalse);
      expect(vm.isLabelSelected('B'), isTrue);
      expect(storage.stored(project.id, 'd0')?.label, {'B'});
      vm.dispose();
    });
  });

  group('CrossClassificationLabelingViewModel', () {
    test('저장된 relation을 복원하고 쌍 단위로 진행률을 계산한다 (초기화 TypeError 회귀)', () async {
      final project = _project(LabelingMode.crossClassification);
      storage.seed(project.id, [
        CrossClassificationLabelModel(
          dataId: 'd0_d2',
          label: const CrossDataPair(sourceId: 'd0', targetId: 'd2', relation: 'A'),
          labeledAt: DateTime(2025),
        ),
      ]);
      final vm = CrossClassificationLabelingViewModel(project: project, storageHelper: storage, labelUseCases: useCases, dataManager: dataFor(project));

      await vm.initialize();

      expect(vm.totalCount, 3, reason: '3C2 = 3 pairs');
      expect(vm.completeCount, 1);
      expect(storage.loadSingleCalls, 0, reason: '쌍마다 개별 로드하지 않아야 함');

      expect(vm.currentItemName, 'd0.csv ↔ d1.csv');
      await vm.moveNext();
      expect(vm.isLabelSelected('A'), isTrue);
      expect(vm.hasNext, isTrue);
      vm.dispose();
    });

    test('setRelation은 쌍 ID로 1회 저장하고, 같은 값 토글 시 해제한다', () async {
      final project = _project(LabelingMode.crossClassification, dataCount: 2);
      final vm = CrossClassificationLabelingViewModel(project: project, storageHelper: storage, labelUseCases: useCases, dataManager: dataFor(project));
      await vm.initialize();

      await vm.toggleLabel('B');
      final saved = storage.stored(project.id, 'd0_d1')?.label as CrossDataPair;
      expect(saved.relation, 'B');
      expect(vm.completeCount, 1);
      expect(storage.saveLabelCalls, 1);

      await vm.toggleLabel('B');
      expect(vm.completeCount, 0);
      expect(vm.hasNext, isFalse);
      vm.dispose();
    });
  });

  group('SegmentationLabelingViewModel', () {
    late Project project;
    late SegmentationLabelingViewModel vm;

    setUp(() async {
      project = _project(LabelingMode.multiClassSegmentation, classes: const ['road', 'car']);
      vm = SegmentationLabelingViewModel(project: project, storageHelper: storage, labelUseCases: useCases, dataManager: dataFor(project), gridSize: 4);
      await vm.initialize();
    });

    tearDown(() => vm.dispose());

    test('stroke는 드래그 중 저장하지 않고 endStroke에서 1회 저장한다', () async {
      vm.beginStroke();
      vm.paintCell(0, 0);
      vm.paintCell(1, 0);
      vm.paintCell(1, 0);
      expect(storage.saveLabelCalls, 0);
      expect(vm.pendingStroke, {(0, 0), (1, 0)});

      await vm.endStroke();

      expect(storage.saveLabelCalls, 1);
      expect(vm.pendingStroke, isEmpty);
      expect(vm.labelGrid[0][0], 1);
      expect(vm.labelGrid[0][1], 1);
      expect(vm.completeCount, 1);
    });

    test('다른 클래스로 칠해도 기존 클래스의 나머지 픽셀은 유지된다 (멀티클래스 덮어쓰기 회귀)', () async {
      vm.beginStroke();
      vm.paintCell(0, 0);
      vm.paintCell(1, 0);
      await vm.endStroke();

      vm.setSelectedClass('car');
      vm.beginStroke();
      vm.paintCell(1, 0);
      vm.paintCell(2, 2);
      await vm.endStroke();

      final seg = vm.currentSegmentation.segments;
      expect(seg['road']!.indices, {(0, 0)});
      expect(seg['car']!.indices, {(1, 0), (2, 2)});
      expect(vm.labelGrid[0][1], 2);
    });

    test('지우개와 초기화', () async {
      vm.beginStroke();
      vm.paintCell(0, 0);
      vm.paintCell(3, 3);
      await vm.endStroke();

      vm.setErasing(true);
      vm.beginStroke();
      vm.paintCell(0, 0);
      await vm.endStroke();
      expect(vm.currentSegmentation.segments['road']!.indices, {(3, 3)});

      await vm.clearLabels();
      expect(vm.currentSegmentation.isEmpty, isTrue);
      expect(vm.completeCount, 0);
    });

    test('그리드 밖 좌표는 무시한다', () {
      vm.beginStroke();
      vm.paintCell(-1, 0);
      vm.paintCell(4, 4);
      expect(vm.pendingStroke, isEmpty);
    });
  });

  test('dispose 이후 늦게 끝난 작업이 notify해도 예외가 나지 않는다', () async {
    final project = _project(LabelingMode.singleClassification);
    final vm = ClassificationLabelingViewModel(project: project, storageHelper: storage, labelUseCases: useCases, dataManager: dataFor(project));
    await vm.initialize();
    final pending = vm.toggleLabel('A');
    vm.dispose();
    await expectLater(pending, completes);
    expect(vm.isDisposed, isTrue);
  });
}
