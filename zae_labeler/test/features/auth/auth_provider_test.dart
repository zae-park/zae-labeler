// test/features/auth/auth_provider_test.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/di/providers.dart';
import 'package:zae_labeler/src/features/auth/providers/auth_provider.dart';
import 'package:zae_labeler/src/platform_helpers/storage/switchable_storage_helper.dart';

import '../../support/in_memory_storage_helper.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  String? get displayName => 'Tester';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  final _controller = StreamController<User?>.broadcast();
  User? _current;

  void emit(User? u) {
    _current = u;
    _controller.add(u);
  }

  @override
  User? get currentUser => _current;

  /// 실제 FirebaseAuth처럼 구독 즉시 현재 상태를 한 번 방출합니다.
  @override
  Stream<User?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 실제 Cloud/Local 헬퍼를 만들지 않고 전환 호출만 기록합니다.
class _RecordingSwitchable extends SwitchableStorageHelper {
  _RecordingSwitchable() : super(InMemoryStorageHelper());
  final calls = <String>[];

  @override
  Future<void> switchToCloud() async => calls.add('cloud');

  @override
  Future<void> switchToLocal() async => calls.add('local');
}

void main() {
  late _FakeAuth auth;
  late _RecordingSwitchable storage;
  late ProviderContainer container;

  setUp(() {
    auth = _FakeAuth();
    storage = _RecordingSwitchable();
    container = ProviderContainer(overrides: [firebaseAuthProvider.overrideWithValue(auth), switchableStorageProvider.overrideWithValue(storage)]);
  });

  tearDown(() => container.dispose());

  test('authProvider는 현재 사용자로 시작하고 인증 상태 변화를 따라간다', () async {
    container.listen(authProvider, (_, __) {});
    expect(container.read(authProvider).isSignedIn, isFalse);

    auth.emit(_FakeUser('u1'));
    await pumpEventQueue();
    expect(container.read(authProvider).isSignedIn, isTrue);
    expect(container.read(authProvider).userName, 'Tester');

    auth.emit(null);
    await pumpEventQueue();
    expect(container.read(authProvider).isSignedIn, isFalse);
  });

  test('authStorageSync: 로그인 상태가 실제로 바뀔 때만 스토리지를 전환하고 revision을 올린다', () async {
    container.listen(authStorageSyncProvider, (_, __) {});
    await pumpEventQueue();
    expect(storage.calls, isEmpty, reason: '시작 시 로그아웃 상태 → 이미 로컬이므로 전환 없음');
    expect(container.read(storageRevisionProvider), 0);

    auth.emit(_FakeUser('u1'));
    await pumpEventQueue();
    auth.emit(_FakeUser('u1'));
    await pumpEventQueue();
    expect(storage.calls, ['cloud']);
    expect(container.read(storageRevisionProvider), 1);

    auth.emit(null);
    await pumpEventQueue();
    expect(storage.calls, ['cloud', 'local']);
    expect(container.read(storageRevisionProvider), 2);
  });
}
