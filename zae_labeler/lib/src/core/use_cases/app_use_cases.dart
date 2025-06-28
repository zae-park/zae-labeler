import 'project/project_use_cases.dart';
import 'label/label_use_cases.dart';

/// ✅ AppUseCases
/// - 앱 전체에서 사용할 UseCase를 통합 제공
/// - Provider에서 DI 주입 시 이 객체 하나만 넘기면 됨
class AppUseCases {
  final ProjectUseCases project;
  final LabelUseCases label;

  AppUseCases({required this.project, required this.label});

  /// ✅ Factory 패턴으로 간편 생성
  factory AppUseCases.from({required ProjectUseCases project, required LabelUseCases label}) => AppUseCases(project: project, label: label);
}
