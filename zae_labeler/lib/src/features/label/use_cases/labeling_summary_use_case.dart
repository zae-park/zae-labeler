import 'package:zae_labeler/src/features/label/use_cases/validate_label_use_case.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/label/repository/label_repository.dart';

class LabelingSummary {
  final int total;
  final int complete;
  final int warning;
  final int incomplete;

  LabelingSummary({required this.total, required this.complete, required this.warning, required this.incomplete});

  factory LabelingSummary.dummy() => LabelingSummary(total: 0, complete: 0, warning: 0, incomplete: 0);

  double get progressRatio => total == 0 ? 0 : complete / total;
}

class LabelingSummaryUseCase {
  final LabelRepository repository;
  final LabelValidationUseCase validUseCase;

  LabelingSummaryUseCase({required this.repository, required this.validUseCase});

  Future<LabelingSummary> load(Project project) async {
    final Map<String, LabelModel> labelMap = await repository.loadLabelMap(project.id);
    final dataInfos = project.dataInfos;

    int complete = 0;
    int warning = 0;

    for (final data in dataInfos) {
      final label = labelMap[data.id];
      final status = validUseCase.getStatus(project, label);

      if (status == LabelStatus.complete) {
        complete++;
      } else if (status == LabelStatus.warning) {
        warning++;
      }
    }

    final total = dataInfos.length;
    final incomplete = total - complete;

    return LabelingSummary(total: total, complete: complete, warning: warning, incomplete: incomplete);
  }
}
