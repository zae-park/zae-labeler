class RunLengthCodec {
  /// ✅ 인코딩: 일반 좌표 Set → RLE 리스트
  static List<Map<String, int>> encode(Set<(int, int)> pixels) {
    final sorted = pixels.toList()..sort((a, b) => a.$2 == b.$2 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    final List<Map<String, int>> encoded = [];

    int? startX;
    int? y;
    int count = 0;

    for (final (x, currentY) in sorted) {
      if (startX == null || x != startX + count || currentY != y) {
        if (startX != null) {
          encoded.add({'x': startX, 'y': y!, 'count': count});
        }
        startX = x;
        y = currentY;
        count = 1;
      } else {
        count++;
      }
    }

    if (startX != null) {
      encoded.add({'x': startX, 'y': y!, 'count': count});
    }

    return encoded;
  }

  /// ✅ 디코딩: RLE 리스트 → Set<(x, y)>
  static Set<(int, int)> decode(List<Map<String, dynamic>> rleList) {
    final Set<(int, int)> result = {};

    for (var rle in rleList) {
      int startX = rle['x']!;
      int y = rle['y']!;
      int count = rle['count'] ?? 1;

      for (int dx = 0; dx < count; dx++) {
        result.add((startX + dx, y));
      }
    }

    return result;
  }
}
