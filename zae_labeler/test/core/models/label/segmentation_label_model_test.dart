import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';

void main() {
  group('SegmentationLabelModel toPayloadJson/fromPayloadJson', () {
    test('SingleClassSegmentationLabelModel serializes and deserializes correctly', () {
      final data = SegmentationData(
        segments: {
          'tree': Segment(indices: {(1, 2)}, classLabel: 'tree'),
        },
      );
      final model = SingleClassSegmentationLabelModel(dataId: 'id1', dataPath: '/img/1.png', label: data, labeledAt: DateTime.parse('2023-01-01T12:00:00Z'));
      // toPayloadJson returns only payload
      final payload = model.toPayloadJson();
      expect(payload, equals(data.toJson()));
      // fromPayloadJson reconstructs properly
      final recreated = SingleClassSegmentationLabelModel.fromPayloadJson(
        dataId: 'id1',
        dataPath: '/img/1.png',
        labeledAt: DateTime.parse('2023-01-01T12:00:00Z'),
        payload: payload,
      );
      expect(recreated.mode, equals(model.mode));
      expect(recreated.label!.segments, equals(model.label!.segments));
    });

    test('MultiClassSegmentationLabelModel serializes and deserializes correctly', () {
      final data = SegmentationData(
        segments: {
          'road': Segment(indices: {(0, 0), (0, 1)}, classLabel: 'road'),
        },
      );
      final model = MultiClassSegmentationLabelModel(dataId: 'id2', label: data, labeledAt: DateTime.now());
      final payload = model.toPayloadJson();
      expect(payload, equals(data.toJson()));
      final recreated = MultiClassSegmentationLabelModel.fromPayloadJson(dataId: 'id2', dataPath: null, labeledAt: model.labeledAt, payload: payload);
      expect(recreated.label!.segments, equals(model.label!.segments));
      expect(recreated.mode, equals(LabelingMode.multiClassSegmentation));
    });
  });

  group('SegmentationLabelModel flags and copyWith', () {
    test('isLabeled and isMultiClass reflect underlying SegmentationData', () {
      // empty label -> not labeled
      final emptyLabel = SegmentationData.empty;
      final single = SingleClassSegmentationLabelModel(dataId: 'id1', label: emptyLabel, labeledAt: DateTime.now());
      expect(single.isLabeled, isFalse);
      expect(single.isMultiClass, isFalse);

      // non-empty label -> labeled
      final nonEmpty = SegmentationData(
        segments: {
          'car': Segment(indices: {(1, 1)}, classLabel: 'car'),
        },
      );
      final multi = MultiClassSegmentationLabelModel(dataId: 'id2', label: nonEmpty, labeledAt: DateTime.now());
      expect(multi.isLabeled, isTrue);
      expect(multi.isMultiClass, isTrue);
    });

    test('copyWith updates label and labeledAt immutably', () {
      final data = SegmentationData(
        segments: {
          'cat': Segment(indices: {(0, 0)}, classLabel: 'cat'),
        },
      );
      final model = SingleClassSegmentationLabelModel(dataId: 'id', label: data, labeledAt: DateTime.now());
      final newLabel = data.addPixel(1, 1, 'cat');
      final newTime = DateTime.now().add(const Duration(seconds: 5));
      final updated = model.copyWith(label: newLabel, labeledAt: newTime);
      // ensure new instance values changed
      expect(updated.label, equals(newLabel));
      expect(updated.labeledAt, equals(newTime));
      // original remains unchanged
      expect(model.label, equals(data));
      // ensure other fields unchanged
      expect(updated.dataId, equals(model.dataId));
    });
  });
}
