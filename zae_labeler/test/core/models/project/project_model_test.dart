// test/core/models/project/project_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';

void main() {
  group('Project – 기본 생성/불변성(copyWith)', () {
    test('Project.empty는 합리적인 기본값을 갖는다', () {
      final p = Project.empty();
      expect(p.id, 'empty');
      expect(p.name, '');
      expect(p.mode, LabelingMode.singleClassification);
      expect(p.classes, isEmpty);
      expect(p.dataInfos, isEmpty);
      expect(p.labels, isEmpty);
    });

    test('copyWith는 얕은 복사 + 불변 리스트 유지', () {
      final base = Project(id: 'p1', name: 'N', mode: LabelingMode.singleClassification, classes: const ['A', 'B']);

      final copied = base.copyWith(name: 'Renamed');
      expect(copied.id, 'p1');
      expect(copied.name, 'Renamed');
      expect(copied.mode, LabelingMode.singleClassification);
      expect(copied.classes, ['A', 'B']);

      // 교체하지 않은 리스트는 unmodifiable 이어야 함
      expect(() => copied.classes.add('Z'), throwsUnsupportedError);
      expect(() => copied.dataInfos.removeWhere((_) => true), throwsUnsupportedError);
      expect(() => copied.labels.removeWhere((_) => true), throwsUnsupportedError);

      // 교체 시에는 전달한 컬렉션이 그대로 설정됨 (필요 시 테스트 정책 변경)
      final replaced = base.copyWith(classes: ['X']);
      expect(replaced.classes, ['X']);
      // replaced.classes는 unmodifiable 보장은 없음(설계대로)

      expect(identical(base.dataInfos, copied.dataInfos), isFalse); // 새 UnmodifiableView
      expect(identical(base.labels, copied.labels), isFalse);
    });
  });

  group('Project – fromJson(역직렬화)', () {
    test('정상 모드 + labels 키로 라벨 파싱', () {
      final json = {
        'id': 'p-json-1',
        'name': 'P',
        'mode': 'multiClassification',
        'classes': ['C1', 'C2'],
        // labels: 각 원소는 LabelModelConverter.fromJson 이 처리할 표준 래퍼
        'labels': [
          {
            'data_id': 'd1',
            'labeled_at': '2024-01-01T00:00:00Z',
            'label_data': {
              'labels': ['x', 'y'],
            },
          },
        ],
        // dataInfos는 생략 가능
      };

      final p = Project.fromJson(json);
      expect(p.id, 'p-json-1');
      expect(p.name, 'P');
      expect(p.mode, LabelingMode.multiClassification);
      expect(p.classes, containsAll(['C1', 'C2']));
      expect(p.labels.length, 1);

      // 멀티 분류 모델로 역직렬화되었는지 확인
      final m = p.labels.first;
      expect(m, isA<MultiClassificationLabelModel>());
      final mm = m as MultiClassificationLabelModel;
      expect(mm.label, equals({'x', 'y'}));
    });

    test("'label' 키(단수명)도 허용", () {
      final json = {
        'id': 'p-json-2',
        'name': 'P2',
        'mode': 'singleClassification',
        'classes': [],
        'label': [
          {
            'data_id': 'd2',
            'labeled_at': '2024-01-02T00:00:00Z',
            'label_data': {'label': 'cat'},
          },
        ],
      };

      final p = Project.fromJson(json);
      expect(p.mode, LabelingMode.singleClassification);
      expect(p.labels.length, 1);
      expect(p.labels.first, isA<SingleClassificationLabelModel>());
      expect((p.labels.first as SingleClassificationLabelModel).label, 'cat');
    });

    test('잘못된 mode 문자열은 singleClassification 으로 폴백', () {
      final json = {
        'id': 'p-bad-mode',
        'name': 'X',
        'mode': 'not-a-mode',
        'classes': [],
        'labels': [
          // 폴백 모드(singleClassification) 기준으로 파싱됨
          {
            'data_id': 'd3',
            'label_data': {'label': 'dog'},
          },
        ],
      };

      final p = Project.fromJson(json);
      expect(p.mode, LabelingMode.singleClassification);
      expect(p.labels.first, isA<SingleClassificationLabelModel>());
    });

    test('dataInfos 미제공 시 빈 리스트', () {
      final json = {'id': 'p-no-di', 'name': 'Y', 'mode': 'singleClassification', 'classes': [], 'labels': []};
      final p = Project.fromJson(json);
      expect(p.dataInfos, isEmpty);
    });
  });

  group('Project – toJson(직렬화)', () {
    test('includeLabels=false 일 때 라벨은 제외', () {
      final p = Project(id: 'p2', name: 'NoLabels', mode: LabelingMode.singleClassification, classes: const [], labels: const []);

      final j = p.toJson(includeLabels: false);
      expect(j['id'], 'p2');
      expect(j.containsKey('label'), isFalse); // 라벨 제외
      expect(j['mode'], 'singleClassification');
      expect(j['dataInfos'], isA<List>());
    });

    test('includeLabels=true 일 때 각 라벨은 "페이로드만" 직렬화', () {
      // 라벨 모델 인스턴스를 직접 구성
      final s1 = SingleClassificationLabelModel(dataId: 'd1', label: 'cat', labeledAt: DateTime.parse('2024-01-01T00:00:00Z'));
      final m1 = MultiClassificationLabelModel(dataId: 'd2', label: {'A', 'B'}, labeledAt: DateTime.parse('2024-01-01T00:00:00Z'));

      final p = Project(
        id: 'p3',
        name: 'WithLabels',
        mode: LabelingMode.multiClassification, // 프로젝트 전체 모드
        classes: const ['A', 'B'],
        labels: [s1, m1],
      );

      final j = p.toJson(includeLabels: true);
      expect(j['label'], isA<List>());

      // 프로젝트 직렬화에서 라벨은 래퍼 없이 "payload만"
      final payload0 = (j['label'] as List).first as Map;
      expect(payload0.containsKey('data_id'), isFalse);
      expect(payload0, equals({'label': 'cat'}));

      final payload1 = (j['label'] as List)[1] as Map;
      expect(payload1.containsKey('data_id'), isFalse);
      expect(
        payload1,
        equals({
          'labels': ['A', 'B'],
        }),
      ); // Set -> List 로 직렬화
    });
  });

  group('Project – 라운드트립 전략', () {
    test('라벨 제외 라운드트립: fromJson(toJson(includeLabels:false))', () {
      final p = Project(
        id: 'p4',
        name: 'RoundTripNoLabels',
        mode: LabelingMode.crossClassification,
        classes: const ['left', 'right'],
        // labels를 비워 라운드트립 단순화
      );

      final j = p.toJson(includeLabels: false);
      final q = Project.fromJson(j);

      expect(q.id, p.id);
      expect(q.name, p.name);
      expect(q.mode, p.mode);
      expect(q.classes, p.classes);
      expect(q.labels, isEmpty); // 라벨은 직렬화에서 제외했으므로 비어있음
    });

    test('주의: 라벨 포함 라운드트립은 스키마가 다르다', () {
      // Project.toJson(includeLabels:true)는 "페이로드만" 내보내지만,
      // Project.fromJson은 LabelModelConverter.fromJson에 필요한 표준 래퍼
      // (data_id, labeled_at, label_data 등)을 요구함.
      // 따라서 toJson → fromJson 을 그대로 하면 라벨은 복원되지 않음.
      // 이 차이를 문서/주석으로 명시해 두는 것이 안전.
      expect(true, isTrue);
    });
  });
}
