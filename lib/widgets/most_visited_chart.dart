import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/dashboard_controller.dart';

Widget MostVisitedChart(BuildContext context, DashboardController controller) {
  final visitPercentages = controller.getCategoryVisitPercentages();

  if (visitPercentages.isEmpty) {
    return Center(
      child: Text(
        'جاري تحميل بيانات الزيارات...',
        style: TextStyle(color: Colors.grey, fontFamily: mainFont),
      ),
    );
  }

  final data = visitPercentages.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return LayoutBuilder(
    builder: (context, constraints) {
      final chartSize = constraints.maxHeight * 0.9;
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%',
                      style: TextStyle(fontSize: 12));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Text(data[index].key,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis);
                  }
                  return Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  color: controller
                      .categoryColors[index % controller.categoryColors.length],
                  width: 20,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(show: true),
        ),
      );
    },
  );
}
