// lib/src/platform_helpers/storage/local_label_store.dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

/// 동기 key-value 저장소(브라우저 localStorage 등)의 최소 인터페이스.
abstract class KeyValueBackend {
  String? get(String key);

  /// 용량 초과 등으로 실패하면 예외를 던집니다.
  void set(String key, String value);

  void remove(String key);

  Iterable<String> get keys;
}

/// 메모리 구현(테스트용). [quotaBytes]를 주면 브라우저처럼 용량 초과 시 예외를 던집니다.
class MemoryKeyValueBackend implements KeyValueBackend {
  MemoryKeyValueBackend({this.quotaBytes});

  final int? quotaBytes;
  final Map<String, String> data = {};
  int writes = 0;

  int get usedBytes => data.entries.fold(0, (sum, e) => sum + e.key.length + e.value.length);

  @override
  String? get(String key) => data[key];

  @override
  void set(String key, String value) {
    final q = quotaBytes;
    if (q != null) {
      final next = usedBytes - (data[key]?.length ?? 0) - (data.containsKey(key) ? key.length : 0) + key.length + value.length;
      if (next > q) throw StateError('QuotaExceededError');
    }
    writes++;
    data[key] = value;
  }

  @override
  void remove(String key) => data.remove(key);

  @override
  Iterable<String> get keys => data.keys.toList();
}

/// 마이그레이션 결과.
class LabelMigrationResult {
  final int migrated;

  /// 용량 부족 등으로 legacy에 남은 항목 수(다음 접근 때 다시 시도).
  final int remaining;

  const LabelMigrationResult(this.migrated, this.remaining);

  bool get isComplete => remaining == 0;

  @override
  String toString() => 'LabelMigrationResult(migrated: $migrated, remaining: $remaining)';
}

/// 프로젝트 라벨을 **항목별 키**로 보관하는 로컬 저장소.
///
/// ### 저장 포맷
/// - v2(현재): `{prefix}labels:v2:{projectId}:{dataId}` → 라벨 래퍼 JSON 1건
///   라벨 1건 저장 = 키 1개 쓰기. (예전에는 프로젝트의 모든 라벨을 매번 다시 직렬화)
/// - v1(legacy): `{prefix}labels:{projectId}` → 라벨 래퍼 JSON 배열
///
/// ### 마이그레이션
/// 프로젝트에 처음 접근할 때 legacy 배열을 v2 키로 옮깁니다.
/// - [chunkSize]개씩 옮기고, 매 청크 뒤 legacy 배열에서 옮긴 항목을 지웁니다.
///   그래서 localStorage(약 5MB)에 전체 사본 두 벌이 동시에 생기지 않습니다.
/// - 도중에 용량이 부족하면 거기서 멈춥니다. 남은 항목은 legacy에 그대로 있고,
///   읽기는 두 포맷을 합쳐서(v2 우선) 돌려주므로 데이터가 사라지지 않습니다. 다음 실행 때 다시 시도합니다.
class LocalLabelStore {
  LocalLabelStore(this.backend, {this.prefix = 'zae_labeler:', this.chunkSize = 200}) : assert(chunkSize > 0);

  final KeyValueBackend backend;
  final String prefix;
  final int chunkSize;

  /// 이번 세션에서 마이그레이션을 끝냈거나(성공) 시도했다가 멈춘(용량 부족) 프로젝트.
  /// 멈춘 경우 매 읽기마다 다시 쓰고 롤백하지 않도록, 다음 실행(새 인스턴스) 때 다시 시도합니다.
  final Set<String> _migrated = {};

  @visibleForTesting
  String legacyKey(String projectId) => '${prefix}labels:$projectId';

  @visibleForTesting
  String entryPrefix(String projectId) => '${prefix}labels:v2:$projectId:';

  String _entryKey(String projectId, String dataId) => '${entryPrefix(projectId)}$dataId';

  // ───────────────────────────────────────────
  // 읽기/쓰기
  // ───────────────────────────────────────────

  /// 라벨 1건 저장(같은 dataId면 교체).
  void save(String projectId, Map<String, dynamic> entry) {
    ensureMigrated(projectId);
    final dataId = entry['data_id'] as String;
    backend.set(_entryKey(projectId, dataId), jsonEncode(entry));
  }

  Map<String, dynamic>? load(String projectId, String dataId) {
    ensureMigrated(projectId);
    final raw = backend.get(_entryKey(projectId, dataId));
    if (raw != null) return _decode(raw);
    return _legacyEntries(projectId).where((e) => e['data_id'] == dataId).firstOrNull;
  }

  /// 프로젝트의 모든 라벨. 마이그레이션이 덜 끝났으면 legacy 항목도 합칩니다(v2 우선).
  List<Map<String, dynamic>> loadAll(String projectId) {
    ensureMigrated(projectId);
    final byId = <String, Map<String, dynamic>>{};
    for (final e in _legacyEntries(projectId)) {
      final id = e['data_id'];
      if (id is String) byId[id] = e;
    }
    final p = entryPrefix(projectId);
    for (final k in backend.keys) {
      if (!k.startsWith(p)) continue;
      final e = _decode(backend.get(k));
      if (e != null) byId[k.substring(p.length)] = e;
    }
    return byId.values.toList();
  }

  /// 프로젝트 라벨 전체 교체.
  void replaceAll(String projectId, List<Map<String, dynamic>> entries) {
    deleteAll(projectId);
    _migrated.add(projectId);
    for (final e in entries) {
      backend.set(_entryKey(projectId, e['data_id'] as String), jsonEncode(e));
    }
  }

  void deleteAll(String projectId) {
    backend.remove(legacyKey(projectId));
    final p = entryPrefix(projectId);
    for (final k in backend.keys.where((k) => k.startsWith(p)).toList()) {
      backend.remove(k);
    }
    _migrated.remove(projectId);
  }

  // ───────────────────────────────────────────
  // 마이그레이션
  // ───────────────────────────────────────────

  /// 이 프로젝트의 legacy 라벨을 v2로 옮깁니다. 이미 끝났으면 아무것도 하지 않습니다.
  LabelMigrationResult ensureMigrated(String projectId) {
    if (_migrated.contains(projectId)) return const LabelMigrationResult(0, 0);
    if (backend.get(legacyKey(projectId)) == null) {
      _migrated.add(projectId);
      return const LabelMigrationResult(0, 0);
    }
    final result = migrate(projectId);
    _migrated.add(projectId);
    return result;
  }

  /// legacy 배열 → v2 키. 청크 단위로 옮기며, 매 청크 뒤 legacy에서 옮긴 항목을 제거합니다.
  @visibleForTesting
  LabelMigrationResult migrate(String projectId) {
    var pending = _legacyEntries(projectId);
    var migrated = 0;

    while (pending.isNotEmpty) {
      final chunk = pending.take(chunkSize).toList();
      final written = <String>[];
      try {
        for (final e in chunk) {
          final id = e['data_id'];
          if (id is! String) continue;
          final key = _entryKey(projectId, id);
          // 이미 v2에 있으면(마이그레이션 이후 저장된 더 최신 값) 덮어쓰지 않습니다.
          if (backend.get(key) == null) {
            backend.set(key, jsonEncode(e));
            written.add(key);
          }
        }
      } catch (err) {
        // 이 청크에서 쓴 키를 되돌리고 멈춤 → 청크 단위로 일관성 유지
        for (final k in written) {
          backend.remove(k);
        }
        debugPrint('⚠️ [LocalLabelStore] migration paused for $projectId ($migrated moved, ${pending.length} left): $err');
        return LabelMigrationResult(migrated, pending.length);
      }

      migrated += chunk.length;
      pending = pending.skip(chunk.length).toList();
      if (pending.isEmpty) {
        backend.remove(legacyKey(projectId));
      } else {
        // 남은 것만 legacy에 다시 씀(크기가 줄어들기만 하므로 용량 초과가 나지 않음)
        backend.set(legacyKey(projectId), jsonEncode(pending));
      }
    }

    debugPrint('✅ [LocalLabelStore] migrated $migrated labels for $projectId');
    return LabelMigrationResult(migrated, 0);
  }

  List<Map<String, dynamic>> _legacyEntries(String projectId) {
    final raw = backend.get(legacyKey(projectId));
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      debugPrint('⚠️ [LocalLabelStore] unreadable legacy labels for $projectId: $e');
      return const [];
    }
  }

  Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
}
