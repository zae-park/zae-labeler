// lib/src/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // RawKeyDownEvent 및 LogicalKeyboardKey 사용을 위해 추가
import 'package:provider/provider.dart';
import '../view_models/labeling_view_model.dart';
import '../models/project_model.dart';
import '../models/label_entry.dart';
import '../charts/time_series_chart.dart';

class LabelingPage extends StatefulWidget {
  const LabelingPage({Key? key}) : super(key: key);

  @override
  _LabelingPageState createState() => _LabelingPageState();
}

class _LabelingPageState extends State<LabelingPage> {
  late FocusNode _focusNode;
  String _selectedMode = 'single_classification';
  final List<String> _modes = [
    'single_classification',
    'multi_classification',
    'segmentation'
  ];

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
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _changeMode(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _changeMode(1);
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId &&
          event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        if (index < labelingVM.project.classes.length) {
          labelingVM.addOrUpdateLabel(labelingVM.currentIndex,
              labelingVM.project.classes[index], _selectedMode);
        }
      }
    }
  }

  // 모드 전환 함수
  void _changeMode(int delta) {
    int currentIndex = _modes.indexOf(_selectedMode);
    int newIndex = currentIndex + delta;

    if (newIndex < 0) {
      newIndex = _modes.length - 1; // 마지막 모드로 순환
    } else if (newIndex >= _modes.length) {
      newIndex = 0; // 첫 번째 모드로 순환
    }

    setState(() {
      _selectedMode = _modes[newIndex];
    });
  }

  // 다운로드 진행도 표시 및 완료 메시지
  Future<void> _downloadLabels(
      BuildContext context, LabelingViewModel labelingVM, bool asZip) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('다운로드 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('라벨링 데이터를 다운로드하고 있습니다...'),
          ],
        ),
      ),
    );

    try {
      String filePath;
      if (asZip) {
        filePath = await labelingVM.downloadLabelsAsZip();
        // ZIP 파일 공유 기능을 추가하려면 여기에서 처리
      } else {
        filePath = await labelingVM.downloadLabelsAsZae();
        // .zae 파일 공유 기능을 추가하려면 여기에서 처리
      }

      if (!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

      Navigator.of(context).pop(); // 다운로드 중 다이얼로그 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 완료: $filePath')),
      );
    } catch (e) {
      if (!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

      Navigator.of(context).pop(); // 다운로드 중 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전달된 프로젝트 객체 받기
    final Project project =
        ModalRoute.of(context)!.settings.arguments as Project;

    return ChangeNotifierProvider(
      create: (_) => LabelingViewModel(project: project),
      child: Consumer<LabelingViewModel>(
        builder: (context, labelingVM, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${project.name} 라벨링'),
              actions: [
                Builder(
                  builder: (context) => PopupMenuButton<String>(
                    onSelected: (value) {
                      final labelingVM = Provider.of<LabelingViewModel>(context,
                          listen: false);
                      if (value == 'zip') {
                        _downloadLabels(context, labelingVM, true);
                      } else if (value == 'no_zip') {
                        _downloadLabels(context, labelingVM, false);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'zip',
                        child: Text('ZIP 압축 후 다운로드'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'no_zip',
                        child: Text('.zae 파일만 다운로드'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: RawKeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKey: (event) => _handleKeyEvent(event, labelingVM),
              child: Column(
                children: [
                  // 라벨링 모드 선택 (세로 리스트)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: _modes.map((mode) {
                        String displayText;
                        switch (mode) {
                          case 'single_classification':
                            displayText = 'Single Classification';
                            break;
                          case 'multi_classification':
                            displayText = 'Multi Classification';
                            break;
                          case 'segmentation':
                            displayText = 'Segmentation';
                            break;
                          default:
                            displayText = mode;
                        }

                        bool isSelected = _selectedMode == mode;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMode = mode;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              displayText,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
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
                  // 라벨 입력 키패드 (프로젝트에서 설정한 클래스만 표시)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: List.generate(labelingVM.project.classes.length,
                          (index) {
                        final label = labelingVM.project.classes[index];
                        final isSelected =
                            labelingVM.isLabelSelected(label, _selectedMode);

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Colors.blueAccent : null,
                          ),
                          onPressed: () {
                            labelingVM.addOrUpdateLabel(
                                labelingVM.currentIndex, label, _selectedMode);
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
                      '현재 라벨: ${labelingVM.currentLabelEntryToString()}',
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
            ),
          );
        },
      ),
    );
  }
}

extension LabelingViewModelExtension on LabelingViewModel {
  String currentLabelEntryToString() {
    LabelEntry entry = currentLabelEntry;
    List<String> labelStrings = [];

    if (entry.singleClassification != null) {
      labelStrings.add('Single: ${entry.singleClassification!.label}');
    }
    if (entry.multiClassification != null &&
        entry.multiClassification!.labels.isNotEmpty) {
      labelStrings
          .add('Multi: ${entry.multiClassification!.labels.join(', ')}');
    }
    if (entry.segmentation != null &&
        entry.segmentation!.label.indice.isNotEmpty) {
      labelStrings
          .add('Segmentation: ${entry.segmentation!.label.classes.join(', ')}');
    }

    return labelStrings.join(' | ');
  }
}
