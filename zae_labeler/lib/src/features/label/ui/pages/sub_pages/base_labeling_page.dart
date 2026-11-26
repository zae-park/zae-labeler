// lib/src/features/label/ui/pages/sub_pages/base_labeling_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zae_labeler/l10n/app_localizations.dart';

import '../../../view_models/labeling_view_model.dart';
import '../../widgets/labeling_progress.dart';
import '../../widgets/navigation_buttons.dart';
import '../../widgets/viewers/viewer_builder.dart';

/// 라벨링 페이지 공통 골격 (템플릿 메서드).
///
/// - VM의 생명주기는 Riverpod provider가 소유하므로, 이 위젯은 **구독만** 합니다(dispose하지 않음).
/// - 모드별 페이지는 [buildModeSpecificUI], [handleNumericKeyInput]을 구현하고 필요 시 [buildViewer]를 override합니다.
abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatelessWidget {
  final T viewModel;

  const BaseLabelingPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // 라벨링 종료 시 true를 반환 → 호출 측(ProjectTile)이 진행률 요약을 새로고침
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final vm = viewModel;
          return Scaffold(
            appBar: buildAppBar(context, vm),
            body: Focus(
              autofocus: true,
              onKeyEvent: (_, event) => _handleKeyEvent(event, vm),
              child: vm.totalCount == 0
                  ? const Center(child: Text('라벨링할 데이터가 없습니다.'))
                  : Column(
                      children: [
                        Expanded(child: buildViewer(context, vm)),
                        buildProgressBar(context, vm),
                        buildModeSpecificUI(context, vm),
                        buildNavigator(vm),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  /// 공통 AppBar
  PreferredSizeWidget buildAppBar(BuildContext context, T vm) {
    final loc = AppLocalizations.of(context)!;
    return AppBar(
      title: Text('${vm.project.name} ${loc.projectTile_label}'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'zip') _downloadLabels(vm);
          },
          itemBuilder: (_) => const [PopupMenuItem<String>(value: 'zip', child: Text('zip 압축 후 다운로드'))],
        ),
      ],
    );
  }

  /// 라벨링 뷰어. 렌더 소스는 VM이 이동 시점에 미리 준비하므로 여기서는 동기적으로 읽기만 합니다.
  Widget buildViewer(BuildContext context, T vm) {
    if (vm.isRenderPending) return const Center(child: CircularProgressIndicator());
    return ViewerBuilder.fromSource(source: vm.currentRenderable(), data: vm.currentData);
  }

  /// 하단 위치 표시 + 이전/다음
  Widget buildNavigator(T vm) => Column(
    children: [
      LabelingProgress(labelingVM: vm),
      NavigationButtons(onPrevious: vm.movePrevious, onNext: vm.moveNext, hasPrevious: vm.hasPrevious, hasNext: vm.hasNext),
    ],
  );

  /// 진행률 바
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

  /// 모드별 라벨 입력 UI
  Widget buildModeSpecificUI(BuildContext context, T vm);

  /// 숫자 키(1~9 → index 0~8) 입력 처리
  void handleNumericKeyInput(T vm, int index);

  KeyEventResult _handleKeyEvent(KeyEvent event, T vm) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.backspace) {
      vm.movePrevious();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      vm.moveNext();
      return KeyEventResult.handled;
    }
    if (key.keyId >= LogicalKeyboardKey.digit1.keyId && key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      handleNumericKeyInput(vm, key.keyId - LogicalKeyboardKey.digit1.keyId);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _downloadLabels(T vm) async {
    try {
      final filePath = await vm.exportAllLabels();
      debugPrint('다운로드 완료: $filePath');
    } catch (e) {
      debugPrint('다운로드 실패: $e');
    }
  }
}
