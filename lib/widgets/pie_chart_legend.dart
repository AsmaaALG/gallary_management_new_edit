import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/dashboard_controller.dart';

Widget PieChartLegend(BuildContext context, DashboardController controller) {
  final isDesktop = MediaQuery.of(context).size.width > 600;
  final legendFontSize = isDesktop ? 14.0 : 12.0;
  final dotSize = isDesktop ? 14.0 : 12.0;
  final spacing = isDesktop ? 20.0 : 5.0;
  final runSpacing = isDesktop ? 12.0 : 8.0;

  return Wrap(
    alignment: WrapAlignment.center,
    spacing: spacing,
    runSpacing: runSpacing,
    children: controller.categoryReservations.entries.map((entry) {
      final index =
          controller.categoryReservations.keys.toList().indexOf(entry.key);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: controller
                  .categoryColors[index % controller.categoryColors.length],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 4),
          Text(
            entry.key,
            style: TextStyle(fontSize: legendFontSize, fontFamily: mainFont),
          ),
          SizedBox(width: 4),
          Text(
            '(${entry.value})',
            style: TextStyle(fontSize: legendFontSize, fontFamily: mainFont),
          ),
        ],
      );
    }).toList(),
  );
}
