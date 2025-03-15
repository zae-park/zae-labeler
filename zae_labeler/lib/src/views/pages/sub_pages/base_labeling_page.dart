import 'package:flutter/material.dart';
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
  T? labelingVM; // ✅ null 가능성을 고려하여 '?' 추가
  bool _isProjectLoaded = false;
  bool _isViewModelInitialized = false; // ✅ ViewModel 초기화 여부 체크

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
      project = ModalRoute.of(context)!.settings.arguments as Project; // ✅ project를 먼저 초기화
      _isProjectLoaded = true;

      // ✅ project가 초기화된 후에 ViewModel 생성 및 초기화 실행
      labelingVM = createViewModel();
      labelingVM!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isViewModelInitialized = true; // ✅ ViewModel 초기화 완료
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

  /// ✅ 공통 AppBar (다운로드 기능 포함)
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

  /// ✅ Viewer (공통 UI)
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

  /// ✅ Navigator (공통 UI)
  Widget buildNavigator(T labelingVM) {
    return NavigationButtons(onPrevious: labelingVM.movePrevious, onNext: labelingVM.moveNext);
  }

  /// ✅ 라벨링 모드별 UI (Segmentation: Painter, Classification: Selector)
  Widget buildModeSpecificUI(T labelingVM);

  @override
  Widget build(BuildContext context) {
    if (!_isViewModelInitialized || labelingVM == null) {
      return const Center(child: CircularProgressIndicator()); // ✅ ViewModel이 초기화될 때까지 Indicator 표시
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
              child: Column(
                children: [
                  Expanded(child: buildViewer(labelingVM)),
                  buildModeSpecificUI(labelingVM), // ✅ 모드별 UI
                  buildNavigator(labelingVM),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ✅ 각 모드별 ViewModel 생성 (오버라이드 필요)
  T createViewModel();

  /// ✅ 다운로드 기능
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
