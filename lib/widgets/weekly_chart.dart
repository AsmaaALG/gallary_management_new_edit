import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gallery_management/constants.dart';

// دالة لإنشاء مخطط الطلبات الأسبوعية
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
            'عدد الطلبات', // نص عنوان المحور Y
            style: TextStyle(
              fontSize: 12,
              fontFamily: mainFont,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      // المخطط نفسه
      Expanded(
        child: BarChart(
          BarChartData(
            barTouchData:
                BarTouchData(enabled: true), // تفعيل التفاعل مع المخطط
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(), // عرض قيمة الطلبات على المحور Y
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
                    switch (value.toInt()) {
                      case 0:
                        return Text('الأسبوع 1',
                            textDirection: textDirectionRTL);
                      case 1:
                        return Text('الأسبوع 2',
                            textDirection: textDirectionRTL);
                      case 2:
                        return Text('الأسبوع 3',
                            textDirection: textDirectionRTL);
                      case 3:
                        return Text('الأسبوع 4',
                            textDirection: textDirectionRTL);
                      default:
                        return Text('');
                    }
                  },
                ),
              ),
              topTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: false)), // عدم إظهار عنوان المحور العلوي
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: false)), // عدم إظهار عنوان المحور الأيمن
            ),
            borderData: FlBorderData(show: true), // إظهار حدود المخطط
            barGroups: data.map((spot) {
              return BarChartGroupData(
                x: spot.x.toInt(), // محور X
                barRods: [
                  BarChartRodData(
                    toY: spot.y, // قيمة الطلبات على المحور Y
                    color: secondaryColor, // لون العمود
                    width: 20, // عرض العمود
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(6)), // زوايا العمود
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}
