/// 파일 종류(콘텐츠 파싱 전략 결정용)
enum FileType { series, object, image, unsupported }

/// 파일명에서 FileType을 판정하는 간단한 규칙.
/// (복잡한 MIME 판정은 상위 레이어 서비스에서 처리해도 됨)
extension FileTypeX on FileType {
  static FileType fromFilename(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) return FileType.series;
    if (lower.endsWith('.json')) return FileType.object;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return FileType.image;
    }
    return FileType.unsupported;
  }

  static FileType fromExtension(String extension) {
    final lower = extension.toLowerCase();
    if (lower == '.csv' || lower == 'csv') return FileType.series;
    if (lower == '.json' || lower == 'json') return FileType.object;
    if (lower == '.png' || lower == 'png' || lower == '.jpg' || lower == 'jpg' || lower == '.jpeg' || lower == 'jpeg') {
      return FileType.image;
    }
    return FileType.unsupported;
  }
}
