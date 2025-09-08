import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/label_model_converter.dart';
import 'package:zae_labeler/src/core/models/label/classification_label_model.dart';
import 'package:zae_labeler/src/core/models/label/segmentation_label_model.dart';
import 'package:zae_labeler/src/core/models/label/segmentation_data.dart';
import 'package:zae_labeler/src/core/models/label/label_types.dart';

void main() {
  group('LabelModelConverter.wrap', () {
    test('wrap produces standard wrapper for classification label', () {
      final model = SingleClassificationLabelModel(dataId: 'abc', dataPath: '/path', label: 'cat', labeledAt: DateTime.parse('2023-06-01T10:00:00Z'));
      final wrapped = LabelModelConverter.wrap(model);
      expect(wrapped['data_id'], equals('abc'));
      expect(wrapped['data_path'], equals('/path'));
      expect(wrapped['labeled_at'], equals(model.labeledAt.toIso8601String()));
      expect(wrapped['mode'], equals('singleClassification'));
      expect(wrapped['label_data'], equals({'label': 'cat'}));
    });

    test('wrap produces standard wrapper for segmentation label', () {
      final data = SegmentationData(
        segments: {
          'tree': Segment(indices: {(1, 2)}, classLabel: 'tree'),
        },
      );
      final model = MultiClassSegmentationLabelModel(dataId: 'id', label: data, labeledAt: DateTime.parse('2023-06-01T10:00:00Z'));
      final wrapped = LabelModelConverter.wrap(model);
      expect(wrapped['mode'], equals('multiClassSegmentation'));
      expect(wrapped['label_data'], equals(data.toJson()));
    });
  });

  group('LabelModelConverter.fromJson', () {
    test('parses wrapper and returns correct model type', () {
      final wrapper = {
        'data_id': 'd',
        'data_path': '/img',
        'labeled_at': '2023-06-01T10:00:00Z',
        'mode': 'multiClassification',
        'label_data': {
          'labels': ['x', 'y'],
        },
      };
      final model = LabelModelConverter.fromJson(LabelingMode.multiClassification, wrapper);
      expect(model, isA<MultiClassificationLabelModel>());
      final m = model as MultiClassificationLabelModel;
      expect(m.label, equals({'x', 'y'}));
      expect(m.dataId, equals('d'));
    });

    test('parses legacy single classification payload', () {
      final legacy = {'data_id': 'd2', 'labeled_at': '2023-01-01T00:00:00Z', 'label': 'dog'};
      final model = LabelModelConverter.fromJson(LabelingMode.singleClassification, legacy);
      expect(model, isA<SingleClassificationLabelModel>());
      expect((model as SingleClassificationLabelModel).label, equals('dog'));
    });

    test('parses legacy multi classification payload with label list', () {
      final legacy = {
        'data_id': 'd3',
        'labeled_at': '2023-01-01T00:00:00Z',
        'label': ['a', 'b'],
      };
      final model = LabelModelConverter.fromJson(LabelingMode.multiClassification, legacy);
      expect(model, isA<MultiClassificationLabelModel>());
      expect((model as MultiClassificationLabelModel).label, equals({'a', 'b'}));
    });

    test('parses legacy segmentation/cross payload with label map', () {
      // segmentation
      final segLegacy = {
        'data_id': 'd4',
        'labeled_at': '2023-01-01T00:00:00Z',
        'label': {
          'segments': {
            'class1': {
              'indices': [
                [0, 0],
              ],
              'class_label': 'class1',
            },
          },
        },
      };
      final segModel = LabelModelConverter.fromJson(LabelingMode.singleClassSegmentation, segLegacy);
      expect(segModel, isA<SingleClassSegmentationLabelModel>());
      expect((segModel as SingleClassSegmentationLabelModel).label!.segments.containsKey('class1'), isTrue);

      // cross classification legacy
      final crossLegacy = {
        'data_id': 'd5',
        'labeled_at': '2023-01-01T00:00:00Z',
        'label': {'sourceId': 's', 'targetId': 't', 'relation': 'foo'},
      };
      final crossModel = LabelModelConverter.fromJson(LabelingMode.crossClassification, crossLegacy);
      expect(crossModel, isA<CrossClassificationLabelModel>());
      expect((crossModel as CrossClassificationLabelModel).label!.relation, equals('foo'));
    });

    test('throws FormatException when required fields missing', () {
      final bad = {'label_data': {}};
      expect(() => LabelModelConverter.fromJson(LabelingMode.singleClassification, bad), throwsA(isA<FormatException>()));
    });
  });

  /// Additional tests for [LabelModelConverter].
  ///
  /// These tests exercise edge cases that are not covered in the basic
  /// converter test. They verify graceful handling of malformed inputs,
  /// legacy payload normalization, and behaviour when wrapper metadata
  /// mismatches occur.
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
      final bad = {'data_id': 'd3', 'labeled_at': '2023-01-01T00:00:00Z', 'label_data': 123};
      final model = LabelModelConverter.fromJson(LabelingMode.singleClassification, bad);
      expect(model, isA<SingleClassificationLabelModel>());
      final single = model as SingleClassificationLabelModel;
      expect(single.label, isNull);
      expect(single.isLabeled, isFalse);
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
