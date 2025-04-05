Future<void> shareTextOnWeb(String title, String text) async {
  throw UnsupportedError('Web sharing is not supported on this platform.');
}

Future<void> shareFileOnMobile(String filePath, {String? text}) async {
  throw UnsupportedError('Mobile file sharing is not supported on this platform.');
}
