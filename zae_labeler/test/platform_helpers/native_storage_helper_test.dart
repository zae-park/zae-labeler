@TestOn('vm') // ← 데스크톱/서버 VM에서 실행
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zae_labeler/src/platform_helpers/storage/native_storage_helper.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

void main() {
  test('readDataBytes reads from filePath and ensureLocalObjectUrl returns path', () async {
    // 임시 파일 준비
    final dir = await Directory.systemTemp.createTemp('native_helper_test_');
    final f = File(p.join(dir.path, 'payload.bin'));
    final payload = Uint8List.fromList(List.generate(16, (i) => i));
    await f.writeAsBytes(payload, flush: true);

    final info = DataInfo(
      id: 'n1',
      fileName: 'payload.bin',
      filePath: f.path, // ← 네이티브 분기에서 필수
      mimeType: 'application/octet-stream',
    );

    final helper = StorageHelperImpl();

    final out = await helper.readDataBytes(info);
    expect(out, isA<Uint8List>());
    expect(out, payload);

    final url = await helper.ensureLocalObjectUrl(info);
    expect(url, f.path);

    await dir.delete(recursive: true);
  });

  test('readDataBytes throws if filePath is missing', () async {
    final info = DataInfo(id: 'n2', fileName: 'missing.bin');
    final helper = StorageHelperImpl();
    expect(
      () => helper.readDataBytes(info),
      throwsA(isA<ArgumentError>()),
    );
  });
}
