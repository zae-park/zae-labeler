import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/platform_helpers/storage/switchable_storage_helper.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

// 최소 가짜: 사용하지 않는 메서드는 noSuchMethod로 던지게 두고,
// 우리가 검증할 메서드만 오버라이드합니다.
class FakeStorageHelper implements StorageHelperInterface {
  int clearCalls = 0;

  @override
  Future<void> clearAllCache() async {
    clearCalls++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('delegation switches & notifies listeners', () async {
    final local = FakeStorageHelper();
    final cloud = FakeStorageHelper();

    // 초기 delegate = local
    final s = SwitchableStorageHelper(local);

    var notified = 0;
    int listener() => notified++;
    s.addListener(listener);

    // 1) 초기 위임 확인
    await s.clearAllCache();
    expect(local.clearCalls, 1);
    expect(cloud.clearCalls, 0);
    expect(notified, 0); // clearAllCache는 notify를 안 부르므로 0

    // 2) delegate 교체 + notify 발생 확인
    await s.switchToForTest(cloud);
    expect(notified, 1);

    // 3) 교체 후 위임 확인
    await s.clearAllCache();
    expect(local.clearCalls, 1);
    expect(cloud.clearCalls, 1);

    s.removeListener(listener);
  });
}
