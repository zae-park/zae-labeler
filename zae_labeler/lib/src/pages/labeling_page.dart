// lib/src/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/labeling_view_model.dart';
import '../models/project_model.dart';
import 'package:fl_chart/fl_chart.dart';

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
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                Provider.of<LabelingViewModel>(context, listen: false)
                    .downloadLabels();
              },
              tooltip: '다운로드',
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
                        ? LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: SideTitles(showTitles: true),
                                bottomTitles: SideTitles(showTitles: true),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: generateSpots(labelingVM.currentData),
                                  isCurved: true,
                                  colors: [Colors.blue],
                                  barWidth: 2,
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          )
                        : const Center(child: Text('데이터가 없습니다.')),
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
                                labelingVM.currentData, index.toString());
                          },
                          child: Text('$index'),
                        ),
                      );
                    }),
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

  // 시계열 데이터 문자열을 차트 데이터 포인트로 변환
  List<FlSpot> generateSpots(String data) {
    // 예시로 콤마로 구분된 숫자 문자열을 사용
    List<String> parts = data.split(',');
    List<FlSpot> spots = [];
    for (int i = 0; i < parts.length; i++) {
      double? value = double.tryParse(parts[i]);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    return spots;
  }
}
