// lib/src/charts/time_series_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TimeSeriesChart extends StatelessWidget {
  final List<double> data;

  const TimeSeriesChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double minY = data.reduce((a, b) => a < b ? a : b);
    double maxY = data.reduce((a, b) => a > b ? a : b);
    double margin = (maxY - minY) * 0.1; // y축 마진 10%

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // 하단 눈금이 잘리지 않도록 패딩 추가
      child: LineChart(
        LineChartData(
          minY: minY - margin,
          maxY: maxY + margin,
          gridData: FlGridData(
            show: true,
            // drawVerticalLine: false, // 수직 Grid Line 비활성화
            getDrawingHorizontalLine: (value) {
              if (value == 0) {
                return FlLine(
                  color: Colors.grey,
                  strokeWidth: 1.5,
                );
              }
              return FlLine(
                color: Colors.grey,
                strokeWidth: 0.8,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: (maxY + margin - (minY - margin)) / 10, // 적절한 간격 설정
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY + margin - (minY - margin)) / 5, // 적절한 간격 설정
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: generateSpots(data),
              isCurved: false, // 곡선 대신 직선으로 표시
              color: Colors.blue,
              barWidth: 2,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // 시계열 데이터를 FlSpot 리스트로 변환
  List<FlSpot> generateSpots(List<double> data) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }
    return spots;
  }
}
