import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart'; // 실제 경로에 맞게 수정

void main() {
  group('FileType.fromExtension', () {
    test('기본 확장자', () {
      expect(FileTypeX.fromExtension('csv'), FileType.series);
      expect(FileTypeX.fromExtension('JSON'), FileType.object);
      expect(FileTypeX.fromExtension('png'), FileType.image);
      expect(FileTypeX.fromExtension(''), FileType.unsupported);
      expect(FileTypeX.fromExtension('weird'), FileType.unsupported);
    });

    test('변형 포맷', () {
      expect(FileTypeX.fromExtension('jsonl'), FileType.series);
      expect(FileTypeX.fromExtension('ndjson'), FileType.series);
      expect(FileTypeX.fromExtension('csv.gz'), FileType.series);
      expect(FileTypeX.fromExtension('json.zip'), FileType.object); // 선택적 규칙
    });
  });

  group('FileType.fromFilename', () {
    test('경로/URL/쿼리 문자열 대응', () {
      expect(FileTypeX.fromFilename('C:/data/sale.CSV'), FileType.series);
      expect(FileTypeX.fromFilename('/var/tmp/payload.json'), FileType.object);
      expect(FileTypeX.fromFilename('https://host/path/img.JPEG?download=1'), FileType.image);
      expect(FileTypeX.fromFilename('no_extension'), FileType.unsupported);
      expect(FileTypeX.fromFilename('folder/.hidden'), FileType.unsupported);
    });
  });

  group('FileType.fromMime (선택)', () {
    test('mime 힌트', () {
      expect(FileTypeX.fromMime('application/json'), FileType.object);
      expect(FileTypeX.fromMime('text/csv'), FileType.series);
      expect(FileTypeX.fromMime('image/webp'), FileType.image);
      expect(FileTypeX.fromMime('application/octet-stream'), FileType.unsupported);
    });
  });
}
