// 플랫폼에 맞는 구현을 선택해서 export
import 'data_loader_interface.dart' if (dart.library.io) 'data_loader_io.dart' if (dart.library.html) 'data_loader_web.dart';

// import 'data_loader_interface.dart';

/// 플랫폼에 맞는 로더를 생성
DataLoader createDataLoader() {
  // dart.library.io 이면 IoDataLoader,
  // dart.library.html 이면 WebDataLoader가 컴파일 타임에 선택됨.
  return (DataLoader as dynamic)();
  // ↑ 위 한 줄은 조건부 import의 "default constructor" trick을 씀.
  // 만약 IDE가 싫어한다면 다음처럼 플랫폼별 이름을 내보내세요:
  // - io/web 파일에서 `class DataLoader implements DataLoader { ... }` 로 선언
  // - 여기서는 그냥 `return DataLoader();`
}
