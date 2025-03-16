import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/data_model.dart';
import '../../../models/project_model.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../viewers/image_viewer.dart';
import '../../viewers/object_viewer.dart';
import '../../viewers/time_series_viewer.dart';
import '../../widgets/navigator.dart';

abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatefulWidget {
  const BaseLabelingPage({Key? key}) : super(key: key);

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
      project = ModalRoute.of(context)!.settings.arguments as Project;
      _isProjectLoaded = true;

      labelingVM = createViewModel();
      labelingVM!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isViewModelInitialized = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// ✅ 키보드 이벤트 핸들러 (공통 처리)
  void _handleKeyEvent(KeyEvent event, T labelingVM) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        labelingVM.movePrevious(); // ✅ 좌측 방향키 → 이전 데이터
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        labelingVM.moveNext(); // ✅ 우측 방향키 → 다음 데이터
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        labelingVM.movePrevious(); // ✅ 백스페이스 → 이전 데이터
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        handleNumericKeyInput(labelingVM, index); // ✅ 숫자 입력 처리
      }
    }
  }

  /// **숫자 키 입력 처리 (각 모드에서 오버라이드 필요)**
  void handleNumericKeyInput(T labelingVM, int index);

  /// ✅ 공통 AppBar
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

  /// ✅ Viewer
  Widget buildViewer(T labelingVM) {
    final unifiedData = labelingVM.currentUnifiedData;
    switch (unifiedData.fileType) {
      case FileType.series:
        return TimeSeriesChart(data: unifiedData.seriesData ?? []);
      case FileType.object:
        return ObjectViewer.fromMap(unifiedData.objectData ?? {});
      case FileType.image:
        return ImageViewer.fromUnifiedData(unifiedData);
      default:
        return const Center(child: Text('지원되지 않는 파일 형식입니다.'));
    }
  }

  /// ✅ 진행도 표시
  Widget buildProgressIndicator(T labelingVM) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '데이터 ${labelingVM.currentIndex + 1} / ${labelingVM.project.dataPaths.length} - ${labelingVM.currentDataFileName}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// ✅ Navigator
  Widget buildNavigator(T labelingVM) {
    return Column(
      children: [
        buildProgressIndicator(labelingVM),
        NavigationButtons(onPrevious: labelingVM.movePrevious, onNext: labelingVM.moveNext),
      ],
    );
  }

  /// ✅ 모드별 UI 구현
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

  /// ✅ ViewModel 생성
  T createViewModel();

  /// ✅ 라벨링 데이터 다운로드 기능 복구
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
