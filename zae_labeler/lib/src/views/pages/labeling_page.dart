import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../view_models/labeling_view_model.dart';
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../viewers/object_viewer.dart';
import '../viewers/time_series_viewer.dart';
import '../viewers/image_viewer.dart';

class LabelingPage extends StatefulWidget {
  const LabelingPage({Key? key}) : super(key: key);

  @override
  _LabelingPageState createState() => _LabelingPageState();
}

class _LabelingPageState extends State<LabelingPage> {
  late FocusNode _focusNode;
  String _selectedMode = 'single_classification';
  final List<String> _modes = ['single_classification', 'multi_classification', 'segmentation'];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, LabelingViewModel labelingVM) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        labelingVM.movePrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        labelingVM.moveNext();
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _changeMode(1);
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _changeMode(-1);
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId && event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        if (index < labelingVM.project.classes.length) {
          labelingVM.addOrUpdateLabel(labelingVM.currentIndex, labelingVM.project.classes[index], _selectedMode);
        }
      }
    }
  }

  void _changeMode(int delta) {
    int currentIndex = _modes.indexOf(_selectedMode);
    int newIndex = currentIndex + delta;

    if (newIndex < 0) {
      newIndex = _modes.length - 1;
    } else if (newIndex >= _modes.length) {
      newIndex = 0;
    }

    setState(() => _selectedMode = _modes[newIndex]);
  }

  Future<void> _downloadLabels(BuildContext context, LabelingViewModel labelingVM) async {
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
      String filePath = await labelingVM.downloadLabelsAsZip();

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('다운로드 완료: $filePath')));
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('다운로드 실패: $e')));
    }
  }

  Widget _buildViewer(LabelingViewModel labelingVM) {
    final fileData = labelingVM.currentFData;

    if (fileData == null) {
      return const Center(child: Text('데이터를 로드 중입니다.'));
    }

    switch (fileData.fileType) {
      case FileType.series:
        return TimeSeriesChart(data: fileData.seriesData ?? []);
      case FileType.object:
        return ObjectViewer.fromMap(fileData.objectData!);
      case FileType.image:
        return ImageViewer.fromBase64(fileData.content);
      default:
        return const Center(child: Text('지원되지 않는 파일 형식입니다.'));
    }
  }

  Future<void> _loadData(BuildContext context) async {
    final labelingVM = Provider.of<LabelingViewModel>(context, listen: false);
    await labelingVM.loadCurrentFileData();
  }

  @override
  Widget build(BuildContext context) {
    final Project project = ModalRoute.of(context)!.settings.arguments as Project;

    return ChangeNotifierProvider(
      create: (_) => LabelingViewModel(project: project),
      child: Consumer<LabelingViewModel>(
        builder: (context, labelingVM, child) {
          if (!labelingVM.isInitialized) {
            return const CircularProgressIndicator();
          }
          return Scaffold(
            appBar: AppBar(
              title: Text('${project.name} 라벨링'),
              actions: [
                Builder(
                  builder: (context) => PopupMenuButton<String>(
                    onSelected: (value) => (value == 'zip') ? _downloadLabels(context, labelingVM) : null,
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[const PopupMenuItem<String>(value: 'zip', child: Text('ZIP 압축 후 다운로드'))],
                  ),
                ),
              ],
            ),
            body: KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (event) => _handleKeyEvent(event, labelingVM),
              child: FutureBuilder<void>(
                future: labelingVM.loadCurrentFileData(),
                // future: labelingVM.loadCurrentData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('데이터 로드 중 오류 발생: ${snapshot.error}'));
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _modes.map((mode) {
                            String displayText;

                            displayText = {
                                  'single_classification': 'Single Classification',
                                  'multi_classification': 'Multi Classification',
                                  'segmentation': 'Segmentation',
                                }[mode] ??
                                mode;

                            bool isSelected = _selectedMode == mode;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedMode = mode),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(color: isSelected ? Colors.blueAccent : Colors.grey[200], borderRadius: BorderRadius.circular(8.0)),
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(),
                      Expanded(child: Padding(padding: const EdgeInsets.all(16.0), child: _buildViewer(labelingVM))),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('데이터 ${labelingVM.currentIndex + 1}/${labelingVM.dataFiles.length} - ${labelingVM.currentFileName}',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: List.generate(labelingVM.project.classes.length, (index) {
                            final label = labelingVM.project.classes[index];
                            final isSelected = labelingVM.isLabelSelected(label, _selectedMode);

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.blueAccent : null),
                              onPressed: () => labelingVM.addOrUpdateLabel(labelingVM.currentIndex, label, _selectedMode),
                              child: Text(label),
                            );
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          // '현재 라벨: ${labelingVM.currentLabelEntryToString()}',
                          '현재 라벨: asd',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(onPressed: () => labelingVM.movePrevious(), child: const Text('이전')),
                            ElevatedButton(onPressed: () => labelingVM.moveNext(), child: const Text('다음')),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
