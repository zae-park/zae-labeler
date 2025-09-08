// test/core/repositories/data_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/repositories/data_repository.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart'; // LabelingMode
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

/// 최소 in-memory Fake (테스트에서 쓰는 메서드만 구현)
class FakeStorageHelper implements StorageHelperInterface {
  List<Project> _projects;
  List<Project>? savedConfig;
  List<Project>? savedList;
  String downloadReturn = 'ok';
  List<Project> importReturn = const [];

  FakeStorageHelper(List<Project> initial) : _projects = List<Project>.from(initial);

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    savedConfig = List<Project>.from(projects);
  }

  @override
  Future<void> saveProjectList(List<Project> projects) async {
    savedList = List<Project>.from(projects);
    _projects = List<Project>.from(projects);
  }

  @override
  Future<String> downloadProjectConfig(Project project) async => downloadReturn;

  @override
  Future<List<Project>> loadProjectFromConfig(String json) async => importReturn;

  @override
  Future<List<Project>> loadProjectList() async => List<Project>.from(_projects);

  // ✅ 나머지 추상 메서드는 여기로 흡수 (분석기 에러 제거)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // ⬇️ DataInfo 간단 생성 (필요 시 네 실제 생성자에 맞춰 수정)
  DataInfo di(String id) => DataInfo.fromJson({'id': id, 'fileName': 'test_datainfo', 'path': '/$id'});

  late Project base;
  late FakeStorageHelper storage;
  late DataRepository repo;

  setUp(() {
    base = Project(id: 'p1', name: 'Proj', mode: LabelingMode.singleClassification, classes: const ['A'], dataInfos: [di('d1')], labels: const <LabelModel>[]);
    storage = FakeStorageHelper([base]);
    repo = DataRepository(storageHelper: storage);
  });

  test('loadDataInfos: 프로젝트 메모리 값 그대로 반환', () {
    final list = repo.loadDataInfos(base);
    expect(list.map((e) => e.id), ['d1']);
  });

  test('saveDataInfos: saveProjectConfig 위임', () async {
    await repo.saveDataInfos(base);
    expect(storage.savedConfig, isNotNull);
    expect(storage.savedConfig!.single.id, 'p1');
  });

  test('exportData: downloadProjectConfig 위임', () async {
    storage.downloadReturn = '{"ok":true}';
    final out = await repo.exportData(base);
    expect(out, '{"ok":true}');
  });

  test('importData: 첫 프로젝트 dataInfos 반환(없으면 빈 리스트)', () async {
    storage.importReturn = [
      base.copyWith(dataInfos: [di('x'), di('y')]),
    ];
    final infos = await repo.importData('json');
    expect(infos.map((e) => e.id), containsAll(['x', 'y']));

    storage.importReturn = const [];
    final none = await repo.importData('json');
    expect(none, isEmpty);
  });

  test('updateDataInfos: 교체 후 saveProjectList 호출', () async {
    await repo.updateDataInfos('p1', [di('n1'), di('n2')]);
    expect(storage.savedList, isNotNull);
    final updated = storage.savedList!.firstWhere((p) => p.id == 'p1');
    expect(updated.dataInfos.map((e) => e.id), ['n1', 'n2']);
  });

  test('addDataInfo: append', () async {
    await repo.addDataInfo('p1', di('d2'));
    final updated = (await storage.loadProjectList()).firstWhere((p) => p.id == 'p1');
    expect(updated.dataInfos.map((e) => e.id), ['d1', 'd2']);
  });

  test('removeDataInfoById: 삭제', () async {
    await repo.addDataInfo('p1', di('d2')); // ['d1','d2']
    await repo.removeDataInfoById('p1', 'd1'); // -> ['d2']
    final updated = (await storage.loadProjectList()).firstWhere((p) => p.id == 'p1');
    expect(updated.dataInfos.map((e) => e.id), ['d2']);
  });
}
