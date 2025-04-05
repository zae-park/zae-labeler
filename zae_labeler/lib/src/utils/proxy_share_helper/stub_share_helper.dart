// abstract class ShareHelper {
//   Future<void> shareProject({
//     required String name,
//     required String jsonString,
//     required Future<String> Function() getFilePath,
//   });

//   Future<void> shareTextOnWeb(String title, String text) async {
//     throw UnsupportedError('Web sharing is not supported on this platform.');
//   }

//   Future<void> shareFileOnMobile(String filePath, {String? text}) async {
//     throw UnsupportedError('Mobile file sharing is not supported on this platform.');
//   }
// }

class ShareHelperInterface {
  Future<void> shareProject({
    required String name,
    required String jsonString,
    required Future<String> Function() getFilePath,
  }) async {
    // noop for testing or unsupported
  }
}
