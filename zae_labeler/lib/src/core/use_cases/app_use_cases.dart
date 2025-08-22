// lib/src/core/use_cases/app_use_cases.dart

/// {@template app_use_cases}
/// ✅ AppUseCases (애플리케이션 파사드)
///
/// - 여러 feature 유스케이스(Project, Label 등)를 **하나로 묶어** UI/DI 경계를 단순화합니다.
/// - **비즈니스 로직/오케스트레이션은 넣지 않습니다.** (그건 각 feature 파사드나 processes 레이어의 역할)
/// - 컴포지션 루트(bootstrap)에서 Repo들로 생성한 feature 유스케이스를 주입해 구성하세요.
///
/// 구조 원칙:
/// - feature별 유스케이스는 feature 폴더 아래(`src/features/.../use_cases/..`)에 둡니다.
/// - app 파사드는 feature를 **참조만** 합니다(의존 방향: app → feature).
/// - 크로스-피처 시나리오가 커지면 `src/core/processes/`에 별도 프로세스 유스케이스를 두세요.
/// {@endtemplate}
import '../../features/project/use_cases/project_use_cases.dart';
import '../../features/label/use_cases/label_use_cases.dart';

class AppUseCases {
  /// 프로젝트 관련 파사드(조회/메타/데이터경로/IO/삭제 등)
  final ProjectUseCases project;

  /// 라벨 관련 파사드(단일/일괄/검증/요약/임포트·익스포트 등)
  final LabelUseCases label;

  const AppUseCases({required this.project, required this.label});

  /// 편의 생성자: 이미 생성한 feature 파사드를 주입하는 형태
  factory AppUseCases.from({required ProjectUseCases project, required LabelUseCases label}) => AppUseCases(project: project, label: label);

  // 🔹 필요 시 여기에 "아주 얇은" 헬퍼만 추가하세요.
  // 예) 디버그/테스트용 단축 호출 등. (비즈니스 로직 X)
}
