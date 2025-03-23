import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/utils/run_length_codec.dart';

void main() {
  group('RunLengthCodec', () {
    test('encode and decode should preserve data', () {
      final original = {(1, 2), (2, 2), (3, 2), (5, 3), (10, 4), (11, 4)};

      final encoded = RunLengthCodec.encode(original);
      final decoded = RunLengthCodec.decode(encoded);

      expect(decoded, equals(original));
    });

    test('encode produces expected RLE output', () {
      final input = {
        (1, 2), (2, 2), (3, 2), // → RLE: x=1, y=2, count=3
        (5, 3), // → RLE: x=5, y=3, count=1
        (10, 4), (11, 4), // → RLE: x=10, y=4, count=2
      };

      final rle = RunLengthCodec.encode(input);

      expect(rle.length, 3);
      expect(rle[0], {'x': 1, 'y': 2, 'count': 3});
      expect(rle[1], {'x': 5, 'y': 3, 'count': 1});
      expect(rle[2], {'x': 10, 'y': 4, 'count': 2});
    });

    test('decode with count missing defaults to 1', () {
      final rle = [
        {'x': 7, 'y': 1},
        {'x': 9, 'y': 1, 'count': 2}
      ];

      final decoded = RunLengthCodec.decode(rle);

      expect(decoded.contains((7, 1)), isTrue);
      expect(decoded.contains((9, 1)), isTrue);
      expect(decoded.contains((10, 1)), isTrue);
    });
  });
}
