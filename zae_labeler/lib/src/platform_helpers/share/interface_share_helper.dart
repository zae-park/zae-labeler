abstract class ShareHelperInterface {
  Future<void> shareProject({
    required String name,
    required String jsonString,
    required Future<String> Function() getFilePath,
  });
}
