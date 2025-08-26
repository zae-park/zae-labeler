@TestOn('browser') // ← 반드시!  flutter test --platform chrome 로 실행
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/platform_helpers/storage/web_storage_helper.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

void main() {
  test('readDataBytes parses data:...;base64 correctly', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final b64 = base64Encode(bytes);
    final info = DataInfo(
      id: 'd1',
      fileName: 'x.bin',
      base64Content: 'data:application/octet-stream;base64,$b64',
      mimeType: 'application/octet-stream',
    );

    final helper = StorageHelperImpl();
    final out = await helper.readDataBytes(info);
    expect(out, isA<Uint8List>());
    expect((out).length, bytes.length);
  });

  test('ensureLocalObjectUrl creates blob: URL and revoke works', () async {
    final bytes = Uint8List.fromList([7, 8, 9]);
    final b64 = base64Encode(bytes);
    final info = DataInfo(
      id: 'd2',
      fileName: 'y.bin',
      base64Content: 'data:application/octet-stream;base64,$b64',
      mimeType: 'application/octet-stream',
    );

    final helper = StorageHelperImpl();
    final url = await helper.ensureLocalObjectUrl(info);
    expect(url, isNotNull);
    expect(url!.startsWith('blob:'), isTrue);

    // should not throw
    await helper.revokeLocalObjectUrl(url);
  });
}
