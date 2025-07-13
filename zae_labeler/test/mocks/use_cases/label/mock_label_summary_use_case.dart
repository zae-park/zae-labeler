import 'package:zae_labeler/src/features/label/use_cases/labeling_summary_use_case.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';

class MockLabelSummaryUseCase extends LabelingSummaryUseCase {
  MockLabelSummaryUseCase({required super.repository, required super.validUseCase});

  @override
  Future<LabelingSummary> load(Project project) async => LabelingSummary.dummy();
}
