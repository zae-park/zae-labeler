import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../use_cases/label_use_cases.dart';
import '../../../project/use_cases/project_use_cases.dart';
import '../../../../core/models/label_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../platform_helpers/storage/get_storage_helper.dart';
import '../../view_models/labeling_view_model.dart';

import '../../../../core/use_cases/app_use_cases.dart';
import '../../repository/label_repository.dart';
import '../../../project/repository/project_repository.dart';

import 'sub_pages/classification_labeling_page.dart';
import 'sub_pages/segmentation_labeling_page.dart';
import 'sub_pages/cross_classification_labeling_page.dart';

class LabelingPage extends StatelessWidget {
  final Project project;

  const LabelingPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final helper = Provider.of<StorageHelperInterface>(context, listen: false);

    // ✅ Repository 준비
    final labelRepo = LabelRepository(storageHelper: helper);
    final projectRepo = ProjectRepository(storageHelper: helper);

    // ✅ AppUseCases 구성
    final appUseCases = AppUseCases.from(project: ProjectUseCases.from(projectRepo), label: LabelUseCases.from(labelRepo));

    return FutureBuilder<LabelingViewModel>(
      future: LabelingViewModelFactory.createAsync(project, helper, appUseCases),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          debugPrint('❌ ViewModel init error: ${snapshot.error}');
          return const Scaffold(body: Center(child: Text('초기화 실패')));
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('데이터 없음')));
        }

        final vm = snapshot.data!;
        debugPrint('[LabelingPage]: ${vm.runtimeType}');
        debugPrint('[LabelingPage]: ${vm.project.mode}');

        switch (project.mode) {
          case LabelingMode.singleClassification:
          case LabelingMode.multiClassification:
            return ClassificationLabelingPage(project: project, viewModel: vm as ClassificationLabelingViewModel);

          case LabelingMode.crossClassification:
            return CrossClassificationLabelingPage(project: project, viewModel: vm as CrossClassificationLabelingViewModel);

          case LabelingMode.singleClassSegmentation:
          case LabelingMode.multiClassSegmentation:
            return SegmentationLabelingPage(project: project, viewModel: vm as SegmentationLabelingViewModel);
        }
      },
    );
  }
}
