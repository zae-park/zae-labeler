// lib/src/charts/time_series_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TimeSeriesChart extends StatelessWidget {
  final List<double> data;

  const TimeSeriesChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: generateSpots(data),
            isCurved: true,
            colors: [Colors.blue],
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
          ),
        ],
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
