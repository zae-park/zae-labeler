import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/l10n/app_localizations.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/base_labeling_view_model.dart';
import 'package:zae_labeler/src/features/project/view_models/managers/progress_notifier.dart';

import '../../../../../core/models/project/project_model.dart';
import '../../../../../views/widgets/navigator.dart';
import '../../../../../views/widgets/shared/labeling_progress.dart';
import '../../../../../views/widgets/shared/viewer_builder.dart';

/// BaseLabelingPage
/// - 라벨링 페이지 공통 기능을 제공하는 추상 클래스
/// - ClassificationLabelingPage 및 SegmentationLabelingPage에서 상속
abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatelessWidget {
  final Project project;
  final T viewModel;

  const BaseLabelingPage({super.key, required this.project, required this.viewModel});

  void _finishLabelingAndPop(BuildContext context, T vm) {
    final ratio = vm.progressRatio;
    final project = vm.project;
    context.read<ProgressNotifier>().updateProgress(project.id, ratio);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finishLabelingAndPop(context, viewModel);
      },
      child: ChangeNotifierProvider<T>.value(
        value: viewModel,
        child: Consumer<T>(
          builder: (context, vm, _) {
            return Scaffold(
              appBar: buildAppBar(context),
              body: KeyboardListener(
                focusNode: FocusNode(),
                autofocus: true,
                onKeyEvent: (event) => _handleKeyEvent(event, vm),
                child: Column(children: [Expanded(child: buildViewer(vm)), buildProgressBar(context, vm), buildModeSpecificUI(vm), buildNavigator(vm)]),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 공통 AppBar
  PreferredSizeWidget buildAppBar(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppBar(
      title: Text('${project.name} ${loc.projectTile_label}'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'zip') _downloadLabels(viewModel);
          },
          itemBuilder: (_) => const [PopupMenuItem<String>(value: 'zip', child: Text("zip 압축 후 다운로드"))],
        ),
      ],
    );
  }

  /// 라벨링 뷰어 (이미지, 시계열 등)
  Widget buildViewer(T vm) => ViewerBuilder(data: vm.currentData);

  /// 하단 네비게이터
  Widget buildNavigator(T vm) => Column(children: [LabelingProgress(labelingVM: vm), NavigationButtons(onPrevious: vm.movePrevious, onNext: vm.moveNext)]);

  /// 라벨링 진행도 표시
  Widget buildProgressBar(BuildContext context, T vm) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: vm.progressRatio,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 10,
          ),
          const SizedBox(height: 4),
          Text(loc.labeling_status_summary(vm.completeCount, vm.warningCount, vm.incompleteCount), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// 모드별 커스텀 UI
  Widget buildModeSpecificUI(T vm);

  /// 키보드 입력 처리 (숫자/이동)
  void handleNumericKeyInput(T vm, int index);

  void _handleKeyEvent(KeyEvent event, T vm) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.backspace) {
      vm.movePrevious();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      vm.moveNext();
    } else if (event.logicalKey.keyId >= LogicalKeyboardKey.digit0.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      final index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId - 1;
      handleNumericKeyInput(vm, index);
    }
  }

  /// 라벨 다운로드
  Future<void> _downloadLabels(T vm) async {
    try {
      final filePath = await vm.exportAllLabels();
      debugPrint('다운로드 완료: $filePath');
    } catch (e) {
      debugPrint('다운로드 실패: $e');
    }
  }
}
