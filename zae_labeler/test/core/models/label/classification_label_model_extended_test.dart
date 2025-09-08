import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/classification_label_model.dart';
import 'package:zae_labeler/src/core/models/label/label_types.dart';

void main() {
  group('SingleClassificationLabelModel', () {
    test('toPayloadJson/fromPayloadJson round‑trip', () {
      final model = SingleClassificationLabelModel(dataId: 'd1', label: 'cat', labeledAt: DateTime.parse('2023-01-01T00:00:00Z'));
      final payload = model.toPayloadJson();
      expect(payload, equals({'label': 'cat'}));

      final recreated = SingleClassificationLabelModel.fromPayloadJson(dataId: 'd1', dataPath: null, labeledAt: model.labeledAt, payload: payload);
      expect(recreated.label, equals('cat'));
      expect(recreated.mode, equals(LabelingMode.singleClassification));
    });

    test('isLabeled/isMultiClass and copyWith', () {
      final model = SingleClassificationLabelModel(dataId: 'd', label: 'abc', labeledAt: DateTime.now());
      expect(model.isLabeled, isTrue);
      expect(model.isMultiClass, isFalse);
      final copy = model.copyWith(label: 'def', labeledAt: model.labeledAt.add(const Duration(seconds: 1)));
      expect(copy.label, equals('def'));
      expect(copy.dataId, equals(model.dataId));
    });
  });

  group('MultiClassificationLabelModel', () {
    test('toPayloadJson/fromPayloadJson round‑trip', () {
      final labels = {'cat', 'dog'};
      final model = MultiClassificationLabelModel(dataId: 'd2', label: labels, labeledAt: DateTime.parse('2024-03-02T12:00:00Z'));
      final payload = model.toPayloadJson();
      expect(
        payload,
        equals({
          'labels': ['cat', 'dog'],
        }),
      );
      final recreated = MultiClassificationLabelModel.fromPayloadJson(dataId: 'd2', dataPath: null, labeledAt: model.labeledAt, payload: payload);
      expect(recreated.label, equals(labels));
      expect(recreated.mode, equals(LabelingMode.multiClassification));
    });

    test('isLabeled/isMultiClass and copyWith', () {
      final model = MultiClassificationLabelModel(dataId: 'm', label: {'a', 'b'}, labeledAt: DateTime.now());
      expect(model.isLabeled, isTrue);
      expect(model.isMultiClass, isTrue);
      final updated = model.copyWith(label: {'x', 'y'});
      expect(updated.label, equals({'x', 'y'}));
      // original unchanged
      expect(model.label, equals({'a', 'b'}));
    });
  });

  group('CrossClassificationLabelModel and CrossDataPair', () {
    test('toPayloadJson/fromPayloadJson round‑trip', () {
      final pair = CrossDataPair(sourceId: 's', targetId: 't', relation: 'rel');
      final model = CrossClassificationLabelModel(dataId: 'd3', label: pair, labeledAt: DateTime.parse('2023-05-05T05:05:05Z'));
      final payload = model.toPayloadJson();
      expect(payload, equals({'sourceId': 's', 'targetId': 't', 'relation': 'rel'}));
      final recreated = CrossClassificationLabelModel.fromPayloadJson(dataId: 'd3', dataPath: null, labeledAt: model.labeledAt, payload: payload);
      expect(recreated.label!.sourceId, equals('s'));
      expect(recreated.label!.targetId, equals('t'));
      expect(recreated.label!.relation, equals('rel'));
      expect(recreated.mode, equals(LabelingMode.crossClassification));
    });

    test('isLabeled/isMultiClass and copyWith', () {
      final pair = CrossDataPair(sourceId: 'a', targetId: 'b', relation: '');
      final model = CrossClassificationLabelModel(dataId: 'd4', label: pair, labeledAt: DateTime.now());
      // relation empty → not labeled
      expect(model.isLabeled, isFalse);
      expect(model.isMultiClass, isFalse);
      final newPair = pair.copyWith(relation: 'related');
      final updated = model.copyWith(label: newPair);
      expect(updated.label!.relation, equals('related'));
      // original unchanged
      expect(model.label!.relation, isEmpty);
    });

    test('CrossDataPair copyWith and toJson/fromJson', () {
      final pair = CrossDataPair(sourceId: 'x', targetId: 'y');
      final updated = pair.copyWith(relation: 'foo');
      expect(updated.sourceId, equals('x'));
      expect(updated.targetId, equals('y'));
      expect(updated.relation, equals('foo'));
      final json = updated.toJson();
      expect(json, equals({'sourceId': 'x', 'targetId': 'y', 'relation': 'foo'}));
      final fromJson = CrossDataPair.fromJson(json);
      expect(fromJson.sourceId, equals(updated.sourceId));
      expect(fromJson.targetId, equals(updated.targetId));
      expect(fromJson.relation, equals(updated.relation));
    });
  });
}
