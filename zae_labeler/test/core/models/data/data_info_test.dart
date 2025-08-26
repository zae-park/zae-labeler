import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

void main() {
  group('DataInfo basics', () {
    test('fromPath 정상 생성', () {
      final info = DataInfo.fromPath('/var/tmp/sample.csv', mimeType: 'text/csv', id: 'fixed-id');
      expect(info.id, 'fixed-id');
      expect(info.sourceType, DataSourceType.path);
      expect(info.normalizedFileName, 'sample.csv');
      expect(info.extension, 'csv');
      expect(info.mimeType, 'text/csv');
    });

    test('fromBase64 / fromObjectUrl', () {
      final b = DataInfo.fromBase64('x.json', 'eyJrIjoxfQ==');
      expect(b.sourceType, DataSourceType.base64);
      expect(b.normalizedFileName, 'x.json');
      expect(b.extension, 'json');

      final u = DataInfo.fromObjectUrl('img.jpeg', 'blob:https://host/abc-123');
      expect(u.sourceType, DataSourceType.objectUrl);
      expect(u.extension, 'jpeg');
    });

    test('copyWith / copyWithClear', () {
      final a = DataInfo.fromPath('a.csv');
      final b = a.copyWith(fileName: 'b.csv');
      expect(b.fileName, 'b.csv');
      expect(a.fileName, isNot('b.csv'));

      final c = b.copyWithClear(clearFilePath: true);
      expect(c.filePath, isNull);
      expect(c.sourceType, DataSourceType.unknown);
    });

    test('toJson / fromJson round-trip', () {
      final a = DataInfo.create(fileName: 'doc.json', base64Content: 'abc', mimeType: 'application/json');
      final j = a.toJson();
      final b = DataInfo.fromJson(j);
      expect(b, equals(a));
    });

    test('fromJson 방어 로직', () {
      expect(() => DataInfo.fromJson({'fileName': 'x.json'}), throwsA(isA<ArgumentError>()));
      expect(() => DataInfo.fromJson({'id': 'id-only'}), throwsA(isA<ArgumentError>()));
    });
  });
}
