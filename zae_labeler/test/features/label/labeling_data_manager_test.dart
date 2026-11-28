// test/features/label/labeling_data_manager_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';
import 'package:zae_labeler/src/features/label/repository/label_repository.dart';
import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart';
import 'package:zae_labeler/src/features/label/view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/labeling_data_manager.dart';
import 'package:zae_labeler/src/features/project/repository/project_repository.dart';

import '../../support/in_memory_storage_helper.dart';

/// 읽은 항목을 기록하는 로더. [gate]가 있으면 완료될 때까지 읽기를 멈춥니다.
class _CountingLoader extends AdaptiveUnifiedDataLoader {
  _CountingLoader(InMemoryStorageHelper storage) : super(uds: UnifiedDataService(), storage: storage);

  final loads = <String>[];
  Completer<void>? gate;

  @override
  Future<UnifiedData> loadOne(DataInfo info) async {
    loads.add(info.id);
    await gate?.future;
    return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: const [1, 2]);
  }
}

Project _project(int n, {LabelingMode mode = LabelingMode.singleClassification}) => Project(
  id: 'p',
  name: 'P',
  mode: mode,
  classes: const ['A'],
  dataInfos: [for (int i = 0; i < n; i++) DataInfo(id: 'd$i', fileName: 'd$i.csv')],
);

void main() {
  late InMemoryStorageHelper storage;
  late _CountingLoader loader;

  setUp(() {
    storage = InMemoryStorageHelper();
    loader = _CountingLoader(storage);
  });

  LabelingDataManager manager(Project p, {int cacheSize = 16}) => LabelingDataManager(project: p, storageHelper: storage, loader: loader, cacheSize: cacheSize);

  test('load()는 목록만 준비하고 파일 내용은 읽지 않는다', () async {
    final m = manager(_project(1000));
    await m.load();

    expect(m.totalCount, 1000);
    expect(loader.loads, isEmpty);
    expect(m.currentData.fileType, FileType.unsupported, reason: '읽기 전에는 내용 없는 항목');
  });

  test('현재 항목과 앞뒤 항목만 읽는다', () async {
    final m = manager(_project(1000));
    await m.load();
    m.jumpTo(10);

    await m.ensureRenderableReadyForCurrent();
    await m.preloadAround();

    expect(loader.loads.toSet(), {'d9', 'd10', 'd11'});
    expect(m.currentRenderable(), [1, 2]);
  });

  test('같은 항목을 동시에 요청하면 한 번만 읽는다', () async {
    final m = manager(_project(3));
    await m.load();
    loader.gate = Completer<void>();

    final a = m.ensureLoaded('d0');
    final b = m.ensureLoaded('d0');
    loader.gate!.complete();
    await Future.wait([a, b]);

    expect(loader.loads, ['d0']);
  });

  test('캐시 크기를 넘으면 오래된 항목부터 내보내고, 현재 항목 주변은 유지한다', () async {
    final m = manager(_project(50), cacheSize: 4);
    await m.load();

    for (int i = 0; i < 20; i++) {
      m.jumpTo(i);
      await m.ensureRenderableReadyForCurrent();
      await m.preloadAround();
    }

    expect(m.loadedCount, lessThanOrEqualTo(4));
    expect(m.isContentLoaded('d19'), isTrue);
    expect(m.isContentLoaded('d18'), isTrue);
    expect(m.isContentLoaded('d0'), isFalse);

    // 내보낸 항목으로 돌아가면 다시 읽는다
    m.jumpTo(0);
    await m.ensureRenderableReadyForCurrent();
    expect(loader.loads.where((id) => id == 'd0').length, 2);
  });

  test('VM 초기화와 이동은 대량 데이터에서도 필요한 항목만 읽는다', () async {
    final p = _project(500);
    final useCases = LabelUseCases.from(LabelRepository(storageHelper: storage), ProjectRepository(storageHelper: storage));
    final vm = ClassificationLabelingViewModel(project: p, storageHelper: storage, labelUseCases: useCases, dataManager: manager(p));

    await vm.initialize();
    expect(vm.totalCount, 500);
    expect(vm.isRenderPending, isFalse);
    expect(loader.loads.length, lessThanOrEqualTo(2), reason: '현재 + 다음 프리로드');

    await vm.moveNext();
    await pumpEventQueue();
    expect(loader.loads.toSet(), {'d0', 'd1', 'd2'});
    vm.dispose();
  });

  test('교차 분류는 현재 쌍의 두 데이터만 읽는다', () async {
    final p = _project(100, mode: LabelingMode.crossClassification);
    final useCases = LabelUseCases.from(LabelRepository(storageHelper: storage), ProjectRepository(storageHelper: storage));
    final vm = CrossClassificationLabelingViewModel(project: p, storageHelper: storage, labelUseCases: useCases, dataManager: manager(p));

    await vm.initialize();
    expect(loader.loads.toSet(), {'d0', 'd1'});
    expect(vm.currentSourceData.fileType, FileType.series);

    await vm.jumpTo(98); // (d0, d99)
    expect(loader.loads.toSet(), {'d0', 'd1', 'd99'});
    expect(vm.currentItemName, 'd0.csv ↔ d99.csv');
    vm.dispose();
  });
}
