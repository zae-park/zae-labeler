import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';

void main() {
  group('UnifiedData factories & invariants', () {
    test('fromSeries builds series-only payload', () {
      final info = DataInfo.fromPath('/tmp/a.csv', id: 'id1');
      final u = UnifiedData.fromSeries(info: info, values: [1, 2, 3]);
      expect(u.fileType, FileType.series);
      expect(u.hasSeries, isTrue);
      expect(u.hasObject, isFalse);
      expect(u.hasImage, isFalse);
      expect(u.seriesData, [1, 2, 3]);
    });

    test('fromObject builds object-only payload', () {
      final info = DataInfo.fromPath('/tmp/b.json', id: 'id2');
      final u = UnifiedData.fromObject(info: info, object: {'k': 'v', 'n': 1});
      expect(u.fileType, FileType.object);
      expect(u.objectData!['k'], 'v');
    });

    test('fromImageBase64 builds image-only payload', () {
      final info = DataInfo.fromPath('/tmp/c.png', id: 'id3');
      final u = UnifiedData.fromImageBase64(info: info, base64: 'iVBORw0KGgoAAAANSUhEUgAAA...');
      expect(u.fileType, FileType.image);
      expect(u.imageBase64, isNotEmpty);
    });

    test('generic ctor enforces invariants', () {
      final info = DataInfo.fromPath('x.csv', id: 'id4');
      expect(
        () => UnifiedData(dataInfo: info, fileType: FileType.series, objectData: {}),
        throwsArgumentError,
      );
      expect(
        () => UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: [double.nan]),
        throwsArgumentError,
      );
    });
  });

  group('copyWith & immutability', () {
    test('copyWith keeps invariants and returns new object', () {
      final info = DataInfo.fromPath('a.csv', id: 'id5');
      final u1 = UnifiedData.fromSeries(info: info, values: [1, 2]);
      final u2 = u1.copyWith(seriesData: [1, 2, 3]);
      expect(u2.seriesData, [1, 2, 3]);
      expect(identical(u1.seriesData, u2.seriesData), isFalse); // 깊은 불변 래핑 확인
    });
  });

  group('json round-trip', () {
    test('series json', () {
      final info = DataInfo.fromPath('a.csv', id: 'id6');
      final u1 = UnifiedData.fromSeries(info: info, values: [1, 2, 3]);
      final j = u1.toJson();
      final u2 = UnifiedData.fromJson(j);
      expect(u2, equals(u1));
    });

    test('object json', () {
      final info = DataInfo.fromPath('b.json', id: 'id7');
      final u1 = UnifiedData.fromObject(info: info, object: {'x': true});
      final j = u1.toJson();
      final u2 = UnifiedData.fromJson(j);
      expect(u2, equals(u1));
    });
  });
}
