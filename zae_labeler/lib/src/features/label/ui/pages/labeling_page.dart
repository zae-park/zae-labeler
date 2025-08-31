import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zae_labeler/src/features/label/view_models/sub_view_models/base_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/segmentation_labeling_view_model.dart';
import 'package:zae_labeler/src/features/project/logic/project_validator.dart';
import 'package:zae_labeler/src/features/project/use_cases/edit_project_use_case.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

import '../../use_cases/label_use_cases.dart';
import '../../../project/use_cases/project_use_cases.dart';
import '../../../../core/models/label/label_model.dart';
import '../../../../core/models/project/project_model.dart';
import '../../view_models/labeling_view_model.dart';

import '../../../../core/use_cases/app_use_cases.dart';
import '../../repository/label_repository.dart';
import '../../../project/repository/project_repository.dart';

import 'sub_pages/classification_labeling_page.dart';
import 'sub_pages/segmentation_labeling_page.dart';
import 'sub_pages/cross_classification_labeling_page.dart';

/// 리팩토링된 LabelingPage:
/// - StatefulWidget로 변경
/// - initState에서 Future 캐시
/// - 초기화 완료 후 VM을 보관하여 dispose 안전하게 호출
class LabelingPage extends StatefulWidget {
  final Project project;

  const LabelingPage({super.key, required this.project});

  @override
  State<LabelingPage> createState() => _LabelingPageState();
}

class _LabelingPageState extends State<LabelingPage> {
  late final StorageHelperInterface _storageHelper;
  late final LabelRepository _labelRepo;
  late final ProjectRepository _projectRepo;
  late final EditProjectUseCase _projectEditor;
  late final AppUseCases _appUseCases;

  late final Future<LabelingViewModel> _initFuture;
  LabelingViewModel? _resolvedVm; // dispose 위해 보관

  @override
  void initState() {
    super.initState();

    // Provider는 initState에서 listen:false로 안전하게 접근 가능
    _storageHelper = Provider.of<StorageHelperInterface>(context, listen: false);

    // Repository & UseCases 구성 (한 번만)
    _labelRepo = LabelRepository(storageHelper: _storageHelper);
    _projectRepo = ProjectRepository(storageHelper: _storageHelper);
    _projectEditor = EditProjectUseCase(projectRepository: _projectRepo, labelRepository: _labelRepo, validator: ProjectValidator());

    _appUseCases = AppUseCases.from(
      project: ProjectUseCases.from(_projectRepo, editor: _projectEditor, labelRepo: _labelRepo),
      label: LabelUseCases.from(_labelRepo, _projectRepo),
    );

    // 초기화 Future를 캐시. 완료되면 VM을 보관해 두었다가 dispose에서 정리
    _initFuture = LabelingViewModelFactory.createAsync(widget.project, _storageHelper, _appUseCases).then((vm) {
      _resolvedVm = vm;
      debugPrint('[LabelingPage] VM initialized: ${vm.runtimeType} / mode=${vm.project.mode}');
      return vm;
    });
  }

  @override
  void dispose() {
    try {
      _resolvedVm?.dispose();
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LabelingViewModel>(
      future: _initFuture, // ✅ 캐시된 Future 사용
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          debugPrint('❌ ViewModel init error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('초기화 실패'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) return const Scaffold(body: Center(child: Text('데이터 없음')));

        final vm = snapshot.data!;
        debugPrint('[LabelingPage]: ${vm.runtimeType}');
        debugPrint('[LabelingPage]: ${vm.project.mode}');

        switch (widget.project.mode) {
          case LabelingMode.singleClassification:
          case LabelingMode.multiClassification:
            return ClassificationLabelingPage(project: widget.project, viewModel: vm as ClassificationLabelingViewModel);
          case LabelingMode.crossClassification:
            return CrossClassificationLabelingPage(project: widget.project, viewModel: vm as CrossClassificationLabelingViewModel);
          case LabelingMode.singleClassSegmentation:
          case LabelingMode.multiClassSegmentation:
            return SegmentationLabelingPage(project: widget.project, viewModel: vm as SegmentationLabelingViewModel);
        }
      },
    );
  }
}
