// test/utils/cross_pair_utils_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/utils/cross_pairing.dart';

void main() {
  group('generateCrossPairs', () {
    test('generates correct number of pairs', () {
      final dataIds = ['A', 'B', 'C'];
      final pairs = generateCrossPairs(dataIds);

      expect(pairs.length, 3); // (A,B), (A,C), (B,C)
    });

    test('generates correct source and target IDs', () {
      final dataIds = ['X', 'Y', 'Z'];
      final pairs = generateCrossPairs(dataIds);

      expect(pairs[0].sourceId, 'X');
      expect(pairs[0].targetId, 'Y');

      expect(pairs[1].sourceId, 'X');
      expect(pairs[1].targetId, 'Z');

      expect(pairs[2].sourceId, 'Y');
      expect(pairs[2].targetId, 'Z');
    });

    test('empty input returns empty list', () {
      final dataIds = <String>[];
      final pairs = generateCrossPairs(dataIds);

      expect(pairs, isEmpty);
    });

    test('single element input returns empty list', () {
      final dataIds = ['OnlyOne'];
      final pairs = generateCrossPairs(dataIds);

      expect(pairs, isEmpty);
    });
  });
}
