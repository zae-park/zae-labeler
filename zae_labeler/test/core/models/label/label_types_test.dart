import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/label_types.dart';

/// Tests for [LabelingMode.displayName] and [LabelStatus].
///
/// These enums provide user‑friendly names and simple state values
/// without additional behaviour. Nevertheless, verifying the mapping
/// helps catch accidental changes.
void main() {
  group('LabelingMode displayName', () {
    test('returns expected human‑readable strings', () {
      expect(LabelingMode.singleClassification.displayName, equals('Single Classification'));
      expect(LabelingMode.multiClassification.displayName, equals('Multi Classification'));
      expect(LabelingMode.crossClassification.displayName, equals('Cross Classification'));
      expect(LabelingMode.singleClassSegmentation.displayName, equals('Segmentation (Binary)'));
      expect(LabelingMode.multiClassSegmentation.displayName, equals('Segmentation (Multi-Class)'));
    });
  });

  group('LabelStatus enum', () {
    test('values are distinct and comparable', () {
      expect(LabelStatus.complete.index, isNot(equals(LabelStatus.incomplete.index)));
      expect(LabelStatus.warning.index, isNot(equals(LabelStatus.complete.index)));
      // enum values should support equality comparison
      expect(LabelStatus.complete == LabelStatus.complete, isTrue);
      expect(LabelStatus.complete == LabelStatus.warning, isFalse);
    });
  });
}
