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
abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatefulWidget {
  final Project project;

  const BaseLabelingPage({Key? key, required this.project}) : super(key: key);

  @override
  BaseLabelingPageState<T> createState();
}

abstract class BaseLabelingPageState<T extends LabelingViewModel> extends State<BaseLabelingPage<T>> {
  late FocusNode _focusNode;
  late Project project;
  T? labelingVM;
  bool _isProjectLoaded = false;
  bool _isViewModelInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_focusNode));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isProjectLoaded) {
      project = widget.project;  // ✅ 수정: 생성자에서 받은 값 사용
      _isProjectLoaded = true;
      initializeViewModel();
    }
  }

  /// **ViewModel 초기화 로직 분리**
  void initializeViewModel() {
    labelingVM = createViewModel();
    labelingVM!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isViewModelInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// **공통 키보드 이벤트 핸들러**
  void _handleKeyEvent(KeyEvent event, T labelingVM) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        labelingVM.movePrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        labelingVM.moveNext();
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        labelingVM.movePrevious();
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId - 1;
        handleNumericKeyInput(labelingVM, index);
      }
    }
  }

  /// **숫자 키 입력 처리 (각 모드에서 오버라이드 필요)**
  void handleNumericKeyInput(T labelingVM, int index);

  /// **공통 AppBar**
  PreferredSizeWidget buildAppBar(T labelingVM) {
    return AppBar(
      title: Text('${project.name} 라벨링'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => (value == 'zip') ? _downloadLabels(context, labelingVM) : null,
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(value: 'zip', child: Text('ZIP 압축 후 다운로드')),
          ],
        ),
      ],
    );
  }

  /// **공통 Viewer**
  Widget buildViewer(T labelingVM) => ViewerBuilder(data: labelingVM.currentUnifiedData);

  /// **공통 Navigator**
  Widget buildNavigator(T labelingVM) {
    return Column(
      children: [
        LabelingProgress(labelingVM: labelingVM),
        NavigationButtons(onPrevious: labelingVM.movePrevious, onNext: labelingVM.moveNext),
      ],
    );
  }

  Widget buildProgressBar(LabelingViewModel vm) {
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
          Text(
            "완료: ${vm.completeCount}  |  주의: ${vm.warningCount}  |  미완료: ${vm.incompleteCount}",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// **모드별 UI 구현 (오버라이드 필요)**
  Widget buildModeSpecificUI(T labelingVM);

  @override
  Widget build(BuildContext context) {
    if (!_isViewModelInitialized || labelingVM == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ChangeNotifierProvider<T>.value(
      value: labelingVM!,
      child: Consumer<T>(
        builder: (context, labelingVM, child) {
          return Scaffold(
            appBar: buildAppBar(labelingVM),
            body: KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (event) => _handleKeyEvent(event, labelingVM),
              child: Column(
                children: [
                  Expanded(child: buildViewer(labelingVM)),
                  buildProgressBar(labelingVM),
                  buildModeSpecificUI(labelingVM),
                  buildNavigator(labelingVM),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// **ViewModel 생성 (각 모드에서 오버라이드 필요)**
  T createViewModel();

  Future<void> _downloadLabels(BuildContext context, T labelingVM) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('다운로드 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('라벨링 데이터를 다운로드하고 있습니다...')],
        ),
      ),
    );

    try {
      String filePath = await labelingVM.exportAllLabels();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('다운로드 완료: $filePath')));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('다운로드 실패: $e')));
    }
  }
}
