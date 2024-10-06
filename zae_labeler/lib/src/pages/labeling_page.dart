// lib/src/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/labeling_view_model.dart';
import '../models/project_model.dart';
import '../charts/time_series_chart.dart';

class LabelingPage extends StatelessWidget {
  const LabelingPage({super.key});

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
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'zip') {
                  Provider.of<LabelingViewModel>(context, listen: false)
                      .downloadLabelsAsZip();
                } else if (value == 'no_zip') {
                  Provider.of<LabelingViewModel>(context, listen: false)
                      .downloadLabelsAsZae();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
          ],
        ),
        body: Consumer<LabelingViewModel>(
          builder: (context, labelingVM, child) {
            return Column(
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
                // 현재 데이터 인덱스 표시
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '데이터 ${labelingVM.currentIndex + 1}/${labelingVM.dataFiles.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                // 라벨 입력 키패드
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(10, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            labelingVM.addOrUpdateLabel(
                                labelingVM.currentIndex, index.toString());
                          },
                          child: Text('$index'),
                        ),
                      );
                    }),
                  ),
                ),
                // 현재 라벨 표시
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Consumer<LabelingViewModel>(
                    builder: (context, labelingVM, child) {
                      if (labelingVM.currentIndex < 0 ||
                          labelingVM.currentIndex >=
                              labelingVM.dataFiles.length) {
                        return const Text(
                          '현재 라벨: 없음',
                          style: TextStyle(fontSize: 16),
                        );
                      }

                      final dataId =
                          labelingVM.dataFiles[labelingVM.currentIndex].path;
                      final label = labelingVM.labels.firstWhere(
                          (labelItem) => labelItem.dataId == dataId,
                          orElse: () => Label(dataId: dataId, labels: []));

                      return Text(
                        '현재 라벨: ${label.labels.join(', ')}',
                        style: const TextStyle(fontSize: 16),
                      );
                    },
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
            );
          },
        ),
      ),
    );
  }
}
