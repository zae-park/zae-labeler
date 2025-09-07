import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/label_model_converter.dart';
import 'package:zae_labeler/src/core/models/label/classification_label_model.dart';
import 'package:zae_labeler/src/core/models/label/label_types.dart';

/// Additional tests for [LabelModelConverter].
///
/// These tests exercise edge cases that are not covered in the basic
/// converter test. They verify graceful handling of malformed inputs,
/// legacy payload normalization, and behaviour when wrapper metadata
/// mismatches occur.
void main() {
  group('LabelModelConverter.fromJson edge cases', () {
    test('falls back to current time when labeled_at is invalid', () {
      final before = DateTime.now();
      final raw = {
        'data_id': 'd1',
        'labeled_at': 'not-a-date',
        'label_data': {'label': 'cat'},
      };
      final model = LabelModelConverter.fromJson(LabelingMode.singleClassification, raw) as SingleClassificationLabelModel;
      // labeledAt should be on or after the time before conversion
      expect(model.labeledAt.isAfter(before) || model.labeledAt.isAtSameMomentAs(before), isTrue);
      expect(model.label, equals('cat'));
    });

    test('mode mismatch in wrapper logs warning but returns requested type', () {
      final wrapper = {
        'data_id': 'd2',
        'labeled_at': '2023-01-01T00:00:00Z',
        'mode': 'multiClassification', // wrapper claims multi but we ask for single
        'label_data': {'label': 'dog'},
      };
      final model = LabelModelConverter.fromJson(LabelingMode.singleClassification, wrapper);
      // should still return single classification
      expect(model, isA<SingleClassificationLabelModel>());
      expect((model as SingleClassificationLabelModel).label, equals('dog'));
    });

    test('throws FormatException when label_data is not a map', () {
      final bad = {
        'data_id': 'd3',
        'labeled_at': '2023-01-01T00:00:00Z',
        'label_data': 123, // invalid type
      };
      expect(() => LabelModelConverter.fromJson(LabelingMode.singleClassification, bad), throwsA(isA<FormatException>()));
    });

    test('normalizes legacy payloads with labels key into multi classification', () {
      final legacy = {
        'data_id': 'd4',
        'labeled_at': '2024-01-01T00:00:00Z',
        // legacy field: labels list without wrapper
        'labels': ['a', 'b'],
      };
      final model = LabelModelConverter.fromJson(LabelingMode.multiClassification, legacy);
      expect(model, isA<MultiClassificationLabelModel>());
      expect((model as MultiClassificationLabelModel).label, equals({'a', 'b'}));
    });
  });
}
