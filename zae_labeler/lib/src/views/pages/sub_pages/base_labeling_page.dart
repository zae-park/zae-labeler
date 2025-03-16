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

/// **BaseLabelingPage**
/// - 라벨링 페이지의 기본 구조를 제공하는 추상 클래스.
/// - 공통 UI 요소(AppBar, Viewer, Navigator)를 포함하며,
///   라벨링 모드별 UI는 `buildModeSpecificUI()`에서 구현해야 함.
/// - ClassificationLabelingPage 및 SegmentationLabelingPage에서 상속받아 사용.
abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatefulWidget {
  const BaseLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<T> createState();
}

/// **BaseLabelingPageState**
/// - BaseLabelingPage의 상태 클래스.
/// - `project`를 관리하며, `labelingVM`을 초기화하고,
///   `buildModeSpecificUI()`를 통해 모드별 UI를 구현해야 함.
abstract class BaseLabelingPageState<T extends LabelingViewModel> extends State<BaseLabelingPage<T>> {
  late FocusNode _focusNode;
  late Project project; // ✅ 현재 라벨링 작업 중인 프로젝트
  T? labelingVM; // ✅ 라벨링을 관리하는 ViewModel (초기에는 null일 수 있음)
  bool _isProjectLoaded = false; // ✅ 프로젝트가 로드되었는지 여부
  bool _isViewModelInitialized = false; // ✅ ViewModel이 초기화되었는지 여부

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // ✅ 키보드 입력을 처리하기 위해 포커스를 요청
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_focusNode));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isProjectLoaded) {
      // ✅ 현재 페이지의 프로젝트 정보 가져오기
      project = ModalRoute.of(context)!.settings.arguments as Project;
      _isProjectLoaded = true;

      // ✅ ViewModel 생성 및 초기화 실행
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
    _focusNode.dispose(); // ✅ FocusNode 해제
    super.dispose();
  }

  /// **공통 AppBar 생성**
  /// - 프로젝트 제목을 표시하며, 다운로드 기능을 제공.
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

  /// **공통 Viewer 생성**
  /// - 프로젝트의 데이터 유형에 따라 적절한 Viewer를 반환.
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

  /// ✅ 진행도 표시 UI 추가
  Widget buildProgressIndicator(T labelingVM) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '데이터 ${labelingVM.currentIndex + 1} / ${labelingVM.project.dataPaths.length} - ${labelingVM.currentDataFileName}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// **공통 Navigator 생성**
  /// - 사용자가 이전/다음 데이터를 이동할 수 있도록 함.
  Widget buildNavigator(T labelingVM) {
    return Column(
      children: [
        buildProgressIndicator(labelingVM), // ✅ 진행도 표시
        NavigationButtons(onPrevious: labelingVM.movePrevious, onNext: labelingVM.moveNext),
      ],
    );
  }

  /// ✅ 키보드 이벤트 핸들러 추가
  void _handleKeyEvent(KeyEvent event, T labelingVM) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        labelingVM.movePrevious(); // ✅ 좌측 방향키 → 이전 데이터
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        labelingVM.moveNext(); // ✅ 우측 방향키 → 다음 데이터
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        labelingVM.movePrevious(); // ✅ 백스페이스 → 이전 데이터 (추가 기능)
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        if (index < labelingVM.project.classes.length) {
          _toggleLabel(labelingVM, labelingVM.project.classes[index]);
        }
      }
    }
  }

  /// **라벨링 모드별 UI 구현 (오버라이드 필요)**
  /// - Classification 모드: LabelSelectorWidget 사용
  /// - Segmentation 모드: GridPainterWidget 사용
  Widget buildModeSpecificUI(T labelingVM);

  @override
  Widget build(BuildContext context) {
    // ✅ ViewModel이 초기화될 때까지 Indicator 표시
    if (!_isViewModelInitialized || labelingVM == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ChangeNotifierProvider<T>.value(
      value: labelingVM!,
      child: Consumer<T>(
        builder: (context, labelingVM, child) {
          return Scaffold(
            appBar: buildAppBar(labelingVM), // ✅ 공통 AppBar
            body: KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (event) => _handleKeyEvent(event, labelingVM), // ✅ 키보드 이벤트 핸들러 적용
              child: Column(
                children: [
                  Expanded(child: buildViewer(labelingVM)), // ✅ 공통 Viewer
                  buildModeSpecificUI(labelingVM), // ✅ 모드별 UI (오버라이드 필요)
                  buildNavigator(labelingVM), // ✅ 공통 Navigator + 진행도 표시
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// **각 모드별 ViewModel 생성 (오버라이드 필요)**
  T createViewModel();

  /// **라벨링 데이터 다운로드 기능**
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
