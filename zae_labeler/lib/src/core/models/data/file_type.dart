/// 파일 종류(콘텐츠 파싱 전략 결정용)
enum FileType { series, object, image, unsupported }

extension FileTypeX on FileType {
  /// 경로/URL/파일명에서 확장자를 추출한다.
  /// - 쿼리/프래그먼트 제거
  /// - 마지막 '/' 이후만 고려
  /// - 마지막 '.' 뒤를 확장자로 간주
  static String _extractExtension(String input) {
    var s = input.trim();

    // 쿼리/프래그먼트 제거 (URL 대응)
    final q = s.indexOf('?');
    if (q >= 0) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h >= 0) s = s.substring(0, h);

    // 경로 구분자 기준 파일명만 취득
    final slash = s.lastIndexOf(RegExp(r'[\\/]+'));
    if (slash >= 0) s = s.substring(slash + 1);

    // 확장자 추출
    final dot = s.lastIndexOf('.');
    if (dot < 0 || dot == s.length - 1) return ''; // 확장자 없음
    return s.substring(dot + 1); // '.' 제외
  }

  /// 파일명/경로/URL에서 FileType 판정
  static FileType fromFilename(String fileNameOrPath) {
    final ext = _extractExtension(fileNameOrPath);
    return fromExtension(ext);
  }

  /// 확장자에서 FileType 판정 ('.' 유무/대소문자 무시)
  static FileType fromExtension(String extension) {
    final lower = extension.trim().toLowerCase();
    if (lower.isEmpty) return FileType.unsupported;

    // 일반 케이스
    if (lower == 'csv') return FileType.series;
    if (lower == 'json') return FileType.object;
    if (lower == 'png' || lower == 'jpg' || lower == 'jpeg') return FileType.image;

    // 선택: 변형 포맷 대응
    if (lower == 'jsonl' || lower == 'ndjson') return FileType.series; // 레코드 스트림
    // 압축 힌트 (.csv.gz/.json.gz 등): 상위에서 해제한다면 굳이 안 봐도 되지만,
    // 아래처럼 한 번 더 벗겨볼 수도 있다.
    if (lower.endsWith('.gz') || lower.endsWith('.zip') || lower.endsWith('.bz2')) {
      final base = lower.replaceAll(RegExp(r'\.(gz|zip|bz2)$'), '');
      return fromExtension(base);
    }

    return FileType.unsupported;
  }

  /// (선택) MIME 힌트로 판정 — 상위 레이어에서 MIME을 알면 먼저 사용
  static FileType fromMime(String mime) {
    final m = mime.trim().toLowerCase();
    if (m == 'application/json' || m.endsWith('+json')) return FileType.object;
    if (m == 'text/csv') return FileType.series;
    if (m.startsWith('image/')) return FileType.image;
    return FileType.unsupported;
  }
}
