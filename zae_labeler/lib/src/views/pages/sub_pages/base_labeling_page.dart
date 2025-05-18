// 📁 lib/src/views/pages/sub_pages/base_labeling_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/project_model.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/navigator.dart';
import '../../widgets/shared/labeling_progress.dart';
import '../../widgets/shared/viewer_builder.dart';

/// **BaseLabelingPage**
/// - 라벨링 페이지의 공통 기능을 제공하는 추상 클래스.
/// - 공통 UI(AppBar, Viewer, Navigator)를 포함하며,
///   모드별 UI는 `buildModeSpecificUI()`에서 오버라이드.
/// - ClassificationLabelingPage 및 SegmentationLabelingPage에서 상속받아 사용.

/// Base class for all labeling pages
abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatelessWidget {
  final Project project;
  final T viewModel;

  const BaseLabelingPage({Key? key, required this.project, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: viewModel,
      child: Consumer<T>(
        builder: (context, vm, child) {
          return Scaffold(
            appBar: buildAppBar(vm),
            body: KeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKeyEvent: (event) => _handleKeyEvent(event, vm),
              child: Column(
                children: [Expanded(child: buildViewer(vm)), buildProgressBar(vm), buildModeSpecificUI(vm), buildNavigator(vm)],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget buildAppBar(T vm) {
    return AppBar(
      title: Text('${project.name} 라벨링'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => (value == 'zip') ? _downloadLabels(viewModel) : null,
          itemBuilder: (BuildContext context) => [const PopupMenuItem<String>(value: 'zip', child: Text('ZIP 압축 후 다운로드'))],
        ),
      ],
    );
  }

  Widget buildViewer(T vm) => ViewerBuilder(data: vm.currentUnifiedData);

  Widget buildNavigator(T vm) {
    return Column(
      children: [LabelingProgress(labelingVM: vm), NavigationButtons(onPrevious: vm.movePrevious, onNext: vm.moveNext)],
    );
  }

  Widget buildProgressBar(T vm) {
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
          Text("완료: ${vm.completeCount}  |  주의: ${vm.warningCount}  |  미완료: ${vm.incompleteCount}", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget buildModeSpecificUI(T vm);
  void handleNumericKeyInput(T vm, int index);

  void _handleKeyEvent(KeyEvent event, T vm) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.backspace) {
        vm.movePrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        vm.moveNext();
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId - 1;
        handleNumericKeyInput(vm, index);
      }
    }
  }

  Future<void> _downloadLabels(T vm) async {
    try {
      // 실제 구현 시 exportAllLabels 호출 후 처리 필요
      final filePath = await vm.exportAllLabels();
      debugPrint('다운로드 완료: $filePath');
    } catch (e) {
      debugPrint('다운로드 실패: $e');
    }
  }
}
