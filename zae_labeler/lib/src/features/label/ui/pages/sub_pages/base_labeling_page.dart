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

/// 저장/동기화 콜백 시그니처
typedef OnSaveCallback<T extends LabelingViewModel> = Future<void> Function(BuildContext context, T vm);

/// BaseLabelingPage
/// - 라벨링 페이지 공통 기능 + 공통 AppBar를 제공하는 베이스 클래스
/// - ClassificationLabelingPage, SegmentationLabelingPage 등에서 상속
abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatefulWidget {
  final Project project;
  final T viewModel;

  /// 선택: 저장/동기화(Cloud Sync) 콜백 (주입 안되면 버튼 클릭 시 안내만 노출)
  final OnSaveCallback<T>? onSave;

  const BaseLabelingPage({super.key, required this.project, required this.viewModel, this.onSave});

  /// 모드별 커스텀 UI(본문)에 해당 — 반드시 구현
  Widget buildModeSpecificUI(T vm);

  /// 숫자 키 처리 — 반드시 구현
  void handleNumericKeyInput(T vm, int index);

  @override
  State<BaseLabelingPage<T>> createState() => _BaseLabelingPageState<T>();
}

class _BaseLabelingPageState<T extends LabelingViewModel> extends State<BaseLabelingPage<T>> {
  bool _isSaving = false;
  late final FocusNode _kbFocusNode;

  @override
  void initState() {
    super.initState();
    _kbFocusNode = FocusNode();
  }

  void _finishLabelingAndPop(BuildContext context, T vm) {
    final ratio = vm.progressRatio;
    final project = vm.project;
    context.read<ProgressNotifier>().updateProgress(project.id, ratio);
    Navigator.pop(context, true);
  }

  Future<void> _onSavePressed(T vm) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (widget.onSave != null) {
        await widget.onSave!(context, vm);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장/동기화 콜백이 아직 연결되지 않았습니다.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('동기화 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finishLabelingAndPop(context, widget.viewModel);
      },
      child: ChangeNotifierProvider<T>.value(
        value: widget.viewModel,
        child: Consumer<T>(
          builder: (context, vm, _) {
            return Scaffold(
              appBar: _buildAppBar(context, vm),
              body: KeyboardListener(
                focusNode: _kbFocusNode,
                autofocus: true,
                onKeyEvent: (event) => _handleKeyEvent(event, vm),
                child: Column(
                  children: [
                    Expanded(child: buildViewer(vm)),
                    buildProgressBar(context, vm),
                    widget.buildModeSpecificUI(vm),
                    buildNavigator(vm),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 공통 AppBar (제목 + zip 다운로드 + 저장/동기화 버튼)
  PreferredSizeWidget _buildAppBar(BuildContext context, T vm) {
    final loc = AppLocalizations.of(context)!;
    return AppBar(
      title: Text('${widget.project.name} ${loc.projectTile_label}', overflow: TextOverflow.ellipsis),
      actions: [
        // 저장/동기화(Cloud) 버튼
        _isSaving
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(tooltip: '저장 / 클라우드 동기화', icon: const Icon(Icons.cloud_upload), onPressed: () => _onSavePressed(vm)),

        // 기타 옵션(예: zip 압축 다운로드)
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'zip') _downloadLabels(vm);
          },
          itemBuilder: (_) => const [PopupMenuItem<String>(value: 'zip', child: Text('zip 압축 후 다운로드'))],
        ),
      ],
    );
  }

  /// 기본값 null: 기본 Viewer 사용.
  /// 서브 페이지에서 Viewer를 완전히 교체하고 싶으면 이걸 오버라이드해 위젯을 반환.
  @protected
  Widget? buildViewerOverride(T vm) => null;

  Widget buildViewer(T vm) {
    // 1) 서브 페이지가 오버라이드 제공하면 그걸 사용
    final custom = buildViewerOverride(vm);
    if (custom != null) return custom;

    // 2) 아니면 기존 공통 뷰어 로직 사용
    final dataKey = vm.currentData.dataInfo.id;
    return FutureBuilder<void>(
      key: ValueKey(dataKey),
      future: vm.ensureRenderableReadyForCurrent(),
      builder: (context, snap) {
        final src = vm.currentRenderable();
        if (src == null) return const Center(child: CircularProgressIndicator());
        return ViewerBuilder.fromSource(source: src, data: vm.currentData);
      },
    );
  }

  /// 하단 네비게이터
  Widget buildNavigator(T vm) => Column(
    children: [
      LabelingProgress(labelingVM: vm),
      NavigationButtons(onPrevious: vm.movePrevious, onNext: vm.moveNext),
    ],
  );

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

  /// 키보드 입력 처리 (숫자/이동)
  void _handleKeyEvent(KeyEvent event, T vm) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.backspace) {
      vm.movePrevious();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      vm.moveNext();
    } else if (event.logicalKey.keyId >= LogicalKeyboardKey.digit0.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      final index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId - 1;
      widget.handleNumericKeyInput(vm, index);
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
