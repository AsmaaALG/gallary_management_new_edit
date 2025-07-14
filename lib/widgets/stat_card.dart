import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16.0 : 12.0,
          vertical: isDesktop ? 12.0 : 10.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 16
                          : isSmallScreen
                              ? 10
                              : 12,
                      color: primaryColor,
                      fontFamily: mainFont,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: isDesktop ? 32 : 20,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 6),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: isDesktop
                    ? 28
                    : isSmallScreen
                        ? 18
                        : 22,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: mainFont,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
