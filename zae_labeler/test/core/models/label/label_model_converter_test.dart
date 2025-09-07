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
}
