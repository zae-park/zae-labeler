// test/features/project/project_providers_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/di/providers.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/project/providers/project_providers.dart';
import 'package:zae_labeler/src/platform_helpers/share/interface_share_helper.dart';

import '../../support/in_memory_storage_helper.dart';

class _FakeShare implements ShareHelperInterface {
  final shared = <String>[];

  @override
  Future<void> shareText(String text) async => shared.add(text);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Project _project(String id, {String name = 'P', List<DataInfo> dataInfos = const []}) =>
    Project(id: id, name: name, mode: LabelingMode.singleClassification, classes: const ['A', 'B'], dataInfos: dataInfos);

void main() {
  late InMemoryStorageHelper storage;
  late _FakeShare share;
  late ProviderContainer container;

  setUp(() {
    storage = InMemoryStorageHelper()..projects = [_project('p1', name: 'First')];
    share = _FakeShare();
    container = ProviderContainer(overrides: [storageHelperProvider.overrideWithValue(storage), shareHelperProvider.overrideWithValue(share)]);
  });

  tearDown(() => container.dispose());

  Future<List<Project>> listNow() => container.read(projectListProvider.future);

  group('projectListProvider', () {
    test('저장소에서 목록을 읽는다', () async {
      expect((await listNow()).map((p) => p.name), ['First']);
    });

    test('upsert는 추가/갱신 후 목록 전체를 저장한다', () async {
      await listNow();
      final notifier = container.read(projectListProvider.notifier);

      await notifier.upsert(_project('p2', name: 'Second'));
      await notifier.upsert(_project('p1', name: 'Renamed'));

      expect(container.read(projectListProvider).value!.map((p) => p.name), ['Renamed', 'Second']);
      expect(storage.projects.map((p) => p.name), ['Renamed', 'Second']);
      expect(storage.saveProjectListCalls, 2);
    });

    test('remove는 프로젝트와 라벨을 모두 지운다', () async {
      storage.seed('p1', [SingleClassificationLabelModel(dataId: 'd', label: 'A', labeledAt: DateTime(2025))]);
      await listNow();

      await container.read(projectListProvider.notifier).remove('p1');

      expect(container.read(projectListProvider).value, isEmpty);
      expect(storage.projects, isEmpty);
      expect(storage.stored('p1', 'd'), isNull);
    });

    test('스토리지가 바뀌면(storageRevision) 목록을 다시 읽는다', () async {
      container.listen(projectListProvider, (_, __) {});
      await listNow();
      expect(storage.loadProjectListCalls, 1);

      storage.projects = [_project('cloud', name: 'Cloud')];
      container.read(storageRevisionProvider.notifier).bump();

      expect((await listNow()).map((p) => p.name), ['Cloud']);
      expect(storage.loadProjectListCalls, 2);
    });

    test('share는 설정을 내보낸 뒤 공유한다', () async {
      final list = await listNow();
      await container.read(projectListProvider.notifier).share(list.first);
      expect(share.shared, ['config://p1']);
    });
  });

  group('projectSummaryProvider', () {
    test('라벨 상태로 진행률을 계산하고, invalidate 시 다시 계산한다', () async {
      storage.projects = [
        _project(
          'p1',
          dataInfos: const [
            DataInfo(id: 'd1', fileName: 'a'),
            DataInfo(id: 'd2', fileName: 'b'),
          ],
        ),
      ];
      storage.seed('p1', [SingleClassificationLabelModel(dataId: 'd1', label: 'A', labeledAt: DateTime(2025))]);
      container.listen(projectSummaryProvider('p1'), (_, __) {});

      var summary = await container.read(projectSummaryProvider('p1').future);
      expect(summary.total, 2);
      expect(summary.complete, 1);

      storage.seed('p1', [SingleClassificationLabelModel(dataId: 'd2', label: 'B', labeledAt: DateTime(2025))]);
      container.invalidate(projectSummaryProvider);
      summary = await container.read(projectSummaryProvider('p1').future);
      expect(summary.complete, 2);
    });
  });

  group('projectEditorProvider', () {
    test('신규 프로젝트: 편집이 목록에 즉시 반영되고 confirm 시 목록 전체를 저장한다', () async {
      await listNow();
      final provider = projectEditorProvider(null);
      container.listen(provider, (_, __) {});
      final editor = container.read(provider.notifier);

      expect(container.read(provider).isEditing, isFalse);
      await editor.setName('Brand new');
      await editor.addClass('C');

      final state = container.read(provider);
      expect(state.project.name, 'Brand new');
      expect(state.project.classes, contains('C'));
      expect(container.read(projectListProvider).value!.map((p) => p.name), contains('Brand new'));

      final saved = await editor.confirm();
      expect(storage.projects.map((p) => p.id), contains(saved.id));
    });

    test('기존 프로젝트: 모드 변경 시 기존 라벨을 삭제한다', () async {
      final existing = (await listNow()).first;
      storage.seed(existing.id, [SingleClassificationLabelModel(dataId: 'd', label: 'A', labeledAt: DateTime(2025))]);
      final provider = projectEditorProvider(existing);
      container.listen(provider, (_, __) {});

      await container.read(provider.notifier).setLabelingMode(LabelingMode.multiClassification);

      expect(container.read(provider).project.mode, LabelingMode.multiClassification);
      expect(container.read(provider).isEditing, isTrue);
      expect(storage.stored(existing.id, 'd'), isNull);
    });

    test('구독이 끊기면 편집 상태가 정리된다', () async {
      final provider = projectEditorProvider(null);
      final sub = container.listen(provider, (_, __) {});
      final firstId = container.read(provider).project.id;

      sub.close();
      await container.pump();

      container.listen(provider, (_, __) {});
      expect(container.read(provider).project.id, isNot(firstId));
    });
  });
}
