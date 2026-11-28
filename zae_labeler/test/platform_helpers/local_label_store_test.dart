// test/platform_helpers/local_label_store_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/platform_helpers/storage/local_label_store.dart';

Map<String, dynamic> _entry(String id, String label) => {
  'data_id': id,
  'data_path': '',
  'mode': 'singleClassification',
  'labeled_at': '2025-01-01T00:00:00.000',
  'label_data': {'label': label},
};

const _p = 'zae_labeler:';

void main() {
  late MemoryKeyValueBackend backend;

  /// 예전 앱이 남긴 v1 포맷 데이터를 심습니다.
  void seedLegacy(String projectId, int n, {String label = 'A'}) {
    backend.data['${_p}labels:$projectId'] = jsonEncode([for (int i = 0; i < n; i++) _entry('d$i', label)]);
  }

  setUp(() => backend = MemoryKeyValueBackend());

  group('v2 포맷', () {
    test('라벨 1건 저장은 키 1개만 쓴다', () {
      final store = LocalLabelStore(backend);
      for (int i = 0; i < 50; i++) {
        store.save('p', _entry('d$i', 'A'));
      }
      backend.writes = 0;

      store.save('p', _entry('d7', 'B'));

      expect(backend.writes, 1);
      expect(store.load('p', 'd7')!['label_data'], {'label': 'B'});
      expect(store.loadAll('p'), hasLength(50));
    });

    test('replaceAll / deleteAll은 해당 프로젝트만 건드린다', () {
      final store = LocalLabelStore(backend)
        ..save('p', _entry('a', 'A'))
        ..save('p', _entry('b', 'A'))
        ..save('other', _entry('x', 'A'));

      store.replaceAll('p', [_entry('c', 'C')]);
      expect(store.loadAll('p').map((e) => e['data_id']), ['c']);

      store.deleteAll('p');
      expect(store.loadAll('p'), isEmpty);
      expect(store.loadAll('other'), hasLength(1));
    });
  });

  group('마이그레이션', () {
    test('첫 접근 시 legacy 배열을 항목별 키로 옮기고 legacy를 지운다', () {
      seedLegacy('p', 450);
      final store = LocalLabelStore(backend, chunkSize: 200);

      final all = store.loadAll('p');

      expect(all, hasLength(450));
      expect(backend.get('${_p}labels:p'), isNull, reason: 'legacy 제거');
      expect(backend.keys.where((k) => k.startsWith('${_p}labels:v2:p:')), hasLength(450));
      expect(store.load('p', 'd123')!['label_data'], {'label': 'A'});
    });

    test('다른 프로젝트의 legacy는 건드리지 않는다(프로젝트별 지연 마이그레이션)', () {
      seedLegacy('p', 3);
      seedLegacy('q', 3);
      final store = LocalLabelStore(backend);

      store.loadAll('p');

      expect(backend.get('${_p}labels:p'), isNull);
      expect(backend.get('${_p}labels:q'), isNotNull);
    });

    test('이미 v2에 있는 값(더 최신)은 legacy로 덮어쓰지 않는다', () {
      seedLegacy('p', 2, label: 'old');
      backend.data['${_p}labels:v2:p:d1'] = jsonEncode(_entry('d1', 'new'));

      final store = LocalLabelStore(backend);
      expect(store.load('p', 'd1')!['label_data'], {'label': 'new'});
      expect(store.load('p', 'd0')!['label_data'], {'label': 'old'});
    });

    test('전체 사본 두 벌은 안 들어가는 용량에서도 청크 단위로 끝까지 옮긴다', () {
      seedLegacy('p', 300);
      final legacyBytes = backend.usedBytes;

      // 같은 데이터를 v2로 저장했을 때의 크기 측정
      final probe = MemoryKeyValueBackend()..data.addAll(backend.data);
      LocalLabelStore(probe).ensureMigrated('p');
      final v2Bytes = probe.usedBytes;

      // v2 한 벌 + 약간의 여유. legacy와 v2를 동시에 다 담을 수는 없다.
      final quota = v2Bytes + v2Bytes ~/ 10;
      expect(quota, lessThan(legacyBytes + v2Bytes));
      backend = MemoryKeyValueBackend(quotaBytes: quota)..data.addAll(backend.data);
      final store = LocalLabelStore(backend, chunkSize: 20);

      final result = store.ensureMigrated('p');

      expect(result.isComplete, isTrue, reason: '$result');
      expect(store.loadAll('p'), hasLength(300));
      expect(backend.get('${_p}labels:p'), isNull);
    });

    test('한 청크도 못 옮길 만큼 꽉 차 있으면 아무것도 잃지 않고 다음 접근 때 다시 시도한다', () {
      seedLegacy('p', 100);
      final full = MemoryKeyValueBackend(quotaBytes: backend.usedBytes + 10)..data.addAll(backend.data);
      final store = LocalLabelStore(full, chunkSize: 50);

      final first = store.ensureMigrated('p');
      expect(first.migrated, 0);
      expect(first.remaining, 100);
      expect(full.keys.where((k) => k.contains('labels:v2:')), isEmpty, reason: '실패한 청크는 롤백');

      // 레거시 데이터는 그대로 읽히고, 같은 세션에서는 다시 쓰기를 시도하지 않는다
      final writesBefore = full.writes;
      expect(store.loadAll('p'), hasLength(100));
      expect(full.writes, writesBefore);
      expect(store.load('p', 'd42')!['data_id'], 'd42');

      // 다른 데이터를 지워 공간이 생기면 다음 접근 때 마저 옮긴다
      final roomy = MemoryKeyValueBackend()..data.addAll(full.data);
      final retry = LocalLabelStore(roomy, chunkSize: 50).ensureMigrated('p');
      expect(retry.isComplete, isTrue);
      expect(roomy.get('${_p}labels:p'), isNull);
    });

    test('마이그레이션 중 손상된 legacy는 지우지 않고 무시한다', () {
      backend.data['${_p}labels:p'] = '{not json';
      final store = LocalLabelStore(backend);

      expect(store.loadAll('p'), isEmpty);
      store.save('p', _entry('d0', 'A'));
      expect(store.loadAll('p'), hasLength(1));
      expect(backend.get('${_p}labels:p'), '{not json', reason: '사용자 데이터는 임의로 삭제하지 않음');
    });
  });
}
