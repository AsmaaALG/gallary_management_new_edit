import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gallery_management/constants.dart';

Widget WeeklyChart(List<FlSpot> data) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // عنوان المحور Y بشكل عمودي
      RotatedBox(
        quarterTurns: -1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70.0),
          child: Text(
            'عدد الطلبات',
            style: TextStyle(
              fontSize: 12,
              fontFamily: mainFont,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      // العمود الرئيسي يحتوي على المخطط والنص تحت محور X
      Expanded(
        child: Column(
          children: [
            // المخطط نفسه
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 13),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'أحد',
                            'اثنين',
                            'ثلاثاء',
                            'أربعاء',
                            'خميس',
                            'جمعة',
                            'سبت',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(fontSize: 11),
                            );
                          } else {
                            return Text('');
                          }
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: data.map((spot) {
                    return BarChartGroupData(
                      x: spot.x.toInt(),
                      barRods: [
                        BarChartRodData(
                          toY: spot.y,
                          color: secondaryColor,
                          width: 20,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            // عنوان محور X
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4),
              child: Text(
                'أيام الأسبوع',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: mainFont,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
