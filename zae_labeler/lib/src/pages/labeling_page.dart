// lib/src/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // RawKeyDownEvent 및 LogicalKeyboardKey 사용을 위해 추가
import 'package:provider/provider.dart';
import '../view_models/labeling_view_model.dart';
import '../models/project_model.dart';
import '../models/label_model.dart';
import '../charts/time_series_chart.dart';

class LabelingPage extends StatefulWidget {
  const LabelingPage({Key? key}) : super(key: key);

  @override
  _LabelingPageState createState() => _LabelingPageState();
}

class _LabelingPageState extends State<LabelingPage> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // 포커스를 받아 키보드 이벤트를 수신할 수 있도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // 키보드 이벤트 핸들러
  void _handleKeyEvent(RawKeyEvent event, LabelingViewModel labelingVM) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (event.isShiftPressed) {
          labelingVM.movePrevious();
        } else {
          labelingVM.moveNext();
        }
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId &&
          event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        if (index < labelingVM.project.classes.length) {
          labelingVM.addOrUpdateLabel(
              labelingVM.currentIndex, labelingVM.project.classes[index]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전달된 프로젝트 객체 받기
    final Project project =
        ModalRoute.of(context)!.settings.arguments as Project;

    return ChangeNotifierProvider(
      create: (_) => LabelingViewModel(project: project),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${project.name} 라벨링'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                Provider.of<LabelingViewModel>(context, listen: false)
                    .downloadLabels(context);
              },
              tooltip: '다운로드',
            ),
          ],
        ),
        body: Consumer<LabelingViewModel>(
          builder: (context, labelingVM, child) {
            return RawKeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKey: (event) => _handleKeyEvent(event, labelingVM),
              child: Column(
                children: [
                  // 데이터 시각화 (fl_chart 사용)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: labelingVM.currentData.isNotEmpty
                          ? TimeSeriesChart(data: labelingVM.currentData)
                          : const Center(child: Text('데이터가 없습니다.')),
                    ),
                  ),
                  // 현재 데이터 인덱스 및 파일명 표시
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '데이터 ${labelingVM.currentIndex + 1}/${labelingVM.dataFiles.length} - ${labelingVM.currentFileName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // 라벨 입력 키패드
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: List.generate(project.classes.length, (index) {
                        final label = project.classes[index];
                        final isSelected = labelingVM.isLabelSelected(label);

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Colors.blueAccent : null,
                          ),
                          onPressed: () {
                            labelingVM.addOrUpdateLabel(
                                labelingVM.currentIndex, label);
                          },
                          child: Text(label),
                        );
                      }),
                    ),
                  ),
                  // 현재 라벨 표시
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '현재 라벨: ${labelingVM.currentLabel}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // 데이터 이동 버튼
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            labelingVM.movePrevious();
                          },
                          child: const Text('이전'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            labelingVM.moveNext();
                          },
                          child: const Text('다음'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
