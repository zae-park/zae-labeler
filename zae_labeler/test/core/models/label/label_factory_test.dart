import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/label_factory.dart';
import 'package:zae_labeler/src/core/models/label/label_types.dart';
import 'package:zae_labeler/src/core/models/label/classification_label_model.dart';
import 'package:zae_labeler/src/core/models/label/segmentation_label_model.dart';

/// Tests for [LabelModelFactory] and its associated helpers.
///
/// The factory is responsible for producing a fresh label model for a
/// given [LabelingMode] with default values and for mapping modes to
/// their concrete Dart types. These tests ensure that each mode
/// produces the expected subtype, that the initial label is `null`, and
/// that the creation time roughly matches the current moment.  They
/// also verify that [LabelModelFactory.expectedType] returns the
/// correct type for every supported mode.
void main() {
  group('LabelModelFactory.createNew', () {
    test('returns correct type with default values', () {
      final now = DateTime.now();

      final sc = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'id_sc');
      expect(sc, isA<SingleClassificationLabelModel>());
      expect(sc.dataId, equals('id_sc'));
      // label should be null on creation
      expect(sc.label, isNull);
      // labeledAt should be very close to now (within a few seconds)
      expect(sc.labeledAt.difference(now).inSeconds.abs() < 3, isTrue);

      final mc = LabelModelFactory.createNew(LabelingMode.multiClassification, dataId: 'id_mc');
      expect(mc, isA<MultiClassificationLabelModel>());
      expect(mc.label, isNull);

      final cc = LabelModelFactory.createNew(LabelingMode.crossClassification, dataId: 'id_cc');
      expect(cc, isA<CrossClassificationLabelModel>());
      expect(cc.label, isNull);

      final sSeg = LabelModelFactory.createNew(LabelingMode.singleClassSegmentation, dataId: 'id_ss');
      expect(sSeg, isA<SingleClassSegmentationLabelModel>());
      expect(sSeg.label, isNull);

      final mSeg = LabelModelFactory.createNew(LabelingMode.multiClassSegmentation, dataId: 'id_ms');
      expect(mSeg, isA<MultiClassSegmentationLabelModel>());
      expect(mSeg.label, isNull);
    });
  });

  group('LabelModelFactory.expectedType', () {
    test('maps each mode to the correct Dart type', () {
      expect(LabelModelFactory.expectedType(LabelingMode.singleClassification), equals(SingleClassificationLabelModel));
      expect(LabelModelFactory.expectedType(LabelingMode.multiClassification), equals(MultiClassificationLabelModel));
      expect(LabelModelFactory.expectedType(LabelingMode.crossClassification), equals(CrossClassificationLabelModel));
      expect(LabelModelFactory.expectedType(LabelingMode.singleClassSegmentation), equals(SingleClassSegmentationLabelModel));
      expect(LabelModelFactory.expectedType(LabelingMode.multiClassSegmentation), equals(MultiClassSegmentationLabelModel));
    });
  });
}
