import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/data_model.dart';

void main() {
  group('DataPath', () {
    test('should serialize and deserialize correctly', () {
      final path = DataPath(fileName: 'test.txt', filePath: '/path/to/test.txt');
      final json = path.toJson();
      final fromJson = DataPath.fromJson(json);

      expect(fromJson.fileName, equals(path.fileName));
      expect(fromJson.filePath, equals(path.filePath));
    });

    test('should serialize base64 content', () {
      final path = DataPath(fileName: 'test.txt', base64Content: 'abc123');
      final json = path.toJson();
      final fromJson = DataPath.fromJson(json);

      expect(fromJson.base64Content, equals('abc123'));
    });
  });
}
