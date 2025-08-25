import 'package:flutter_test/flutter_test.dart';
// 실제 경로에 맞춰 import 수정
import 'package:zae_labeler/src/core/models/data/file_type.dart';

void main() {
  group('FileType', () {
    test('기본 확장자 매핑이 기대대로 동작한다', () {
      expect(FileTypeX.fromExtension('json'), FileType.object);
      expect(FileTypeX.fromExtension('CSV'), FileType.series);
      expect(FileTypeX.fromExtension('png'), FileType.image);
      expect(FileTypeX.fromExtension('jpg'), FileType.image);
      expect(FileTypeX.fromExtension('jpeg'), FileType.image);
      expect(FileTypeX.fromExtension('txt'), FileType.unsupported);
    });

    test('미지원 확장자는 unknown으로 처리한다', () {
      expect(FileTypeX.fromExtension('parquet'), FileType.unsupported);
      expect(FileTypeX.fromExtension(''), FileType.unsupported);
      expect(FileTypeX.fromExtension('???'), FileType.unsupported);
    });

    test('MIME 힌트가 있으면 우선한다(있다면)', () {
      // 네 구현에 MIME→타입 헬퍼가 있다면 활성화
      // expect(FileType.fromMime('application/json'), FileType.json);
      // expect(FileType.fromMime('text/csv'), FileType.csv);
    });
  });
}
