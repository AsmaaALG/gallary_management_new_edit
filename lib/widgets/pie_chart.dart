import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/dashboard_controller.dart';

Widget PieChartWidget(DashboardController controller) {
  if (controller.pieChartSections.isEmpty) {
    return Center(
      child: Text(
        'جاري تحميل بيانات الطلبات...',
        style: TextStyle(color: Colors.grey, fontFamily: mainFont),
      ),
    );
  }

  return PieChart(
    PieChartData(
      sections: controller.pieChartSections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
      startDegreeOffset: 270,
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
      ),
    ),
  );
}
