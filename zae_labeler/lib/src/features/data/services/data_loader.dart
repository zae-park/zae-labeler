// lib/src/features/data/services/data_loader.dart
import 'data_loader_interface.dart';

// 웹이면 web 구현, 아니면 io 구현을 끼웁니다.
import 'data_loader_io.dart' if (dart.library.html) 'data_loader_web.dart' as platform;

/// 플랫폼에 맞는 DataLoader 인스턴스를 돌려주는 팩토리
DataLoader createDataLoader() => platform.createDataLoader();
