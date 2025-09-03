// lib/src/platform_helpers/pickers/data_info_picker_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart' as mime;

import '../../core/models/data/data_info.dart';
import 'data_info_picker_interface.dart';

class PlatformDataInfoPicker implements DataInfoPicker {
  final FirebaseAuth _auth;
  PlatformDataInfoPicker({required FirebaseAuth auth}) : _auth = auth;

  static const _allowExts = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'json'];
  static const _uploadTimeout = Duration(seconds: 12); // ⏱ 업로드 타임아웃
  static const _urlTimeout = Duration(seconds: 8); // ⏱ URL 타임아웃

  // 프로젝트 컨텍스트를 받는 버전으로 변경 (필요시 기존 pick()은 래핑)
  Future<List<DataInfo>> pickForProject(String projectId) async => _pickImpl(projectId: projectId);

  @override
  Future<List<DataInfo>> pick() async => _pickImpl(projectId: 'misc');

  Future<List<DataInfo>> _pickImpl({required String projectId}) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      withReadStream: true,
      type: FileType.custom,
      allowedExtensions: _allowExts,
    );
    debugPrint('[Picker.web] result=$res');
    if (res == null) return const [];

    final uid = _auth.currentUser?.uid ?? 'guest';
    final out = <DataInfo>[];

    for (final f in res.files) {
      // 1) bytes or stream → Uint8List
      Uint8List? bytes = f.bytes;
      if (bytes == null && f.readStream != null) {
        final collected = <int>[];
        try {
          await for (final chunk in f.readStream!) {
            collected.addAll(chunk);
          }
          bytes = Uint8List.fromList(collected);
          debugPrint('[Picker.web] stream collected: ${f.name}, len=${bytes.length}, expected=${f.size}');
        } catch (e, st) {
          debugPrint('❌ [Picker.web] stream read failed: ${f.name}: $e\n$st');
          continue;
        }
      }
      if (bytes == null) {
        debugPrint('⚠️ [Picker.web] no bytes & no stream for ${f.name}, skip.');
        continue;
      }

      // 2) MIME
      final ct = mime.lookupMimeType(f.name, headerBytes: bytes) ?? 'application/octet-stream';
      final isJson = ct.contains('json') || f.name.toLowerCase().endsWith('.json');
      final isImage = ct.startsWith('image/');

      if (!isJson && !isImage) {
        debugPrint('⚠️ [Picker.web] unsupported mime=$ct for ${f.name}, skip.');
        continue;
      }

      // 3) 업로드 + URL with timeout → 실패 시 세션 폴백
      try {
        final fullPath = await _uploadWithTimeout(uid: uid, projectId: projectId, fileName: f.name, bytes: bytes, contentType: ct);
        out.add(DataInfo.create(fileName: f.name, filePath: fullPath, mimeType: ct, base64Content: null, objectUrl: null));
        debugPrint('[Picker.web] added (cloud-path): ${f.name} -> $fullPath');
      } on TimeoutException catch (e) {
        debugPrint('⏳ [Picker.web] upload/url timeout for ${f.name}: $e');
        _addSessionFallback(out, f.name, bytes, ct, isJson, isImage);
      } catch (e, st) {
        debugPrint('❌ [Picker.web] upload failed: ${f.name}: $e\n$st');
        _addSessionFallback(out, f.name, bytes, ct, isJson, isImage);
      }
    }

    debugPrint('[Picker.web] produced DataInfos=${out.length}');
    return out;
  }

  Future<String> _uploadWithTimeout({
    required String uid,
    required String projectId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safe = fileName.replaceAll(RegExp(r'[^\w\\-. ]+'), '_');
    // ✅ 프로젝트 스코프 + data 폴더 + 타임스탬프(or UUID) 접두
    final fullPath = 'users/$uid/projects/$projectId/data/${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = fb.FirebaseStorage.instance.ref(fullPath);
    debugPrint('[Picker.web] upload: $fullPath ct=$contentType size=${bytes.length}');

    await ref.putData(bytes, fb.SettableMetadata(contentType: contentType)).timeout(_uploadTimeout);
    // 여기서 다운로드 URL은 만들지 않습니다. fullPath만 반환.
    return fullPath; // ← 이 값을 DataInfo.filePath로 사용
  }

  void _addSessionFallback(List<DataInfo> out, String name, Uint8List bytes, String ct, bool isJson, bool isImage) {
    final b64 = base64Encode(bytes);

    if (isJson) {
      out.add(
        DataInfo.create(
          fileName: name,
          filePath: null, // 세션 전용(리프레시 시 유실 가능)
          mimeType: 'application/json',
          base64Content: 'data:application/json;base64,$b64',
          objectUrl: null,
        ),
      );
      debugPrint('[Picker.web] added (session/json-base64): $name');
    } else if (isImage) {
      out.add(DataInfo.create(fileName: name, filePath: null, mimeType: ct, base64Content: 'data:$ct;base64,$b64', objectUrl: null));
      debugPrint('[Picker.web] added (session/image-base64): $name');
    }
  }
}
