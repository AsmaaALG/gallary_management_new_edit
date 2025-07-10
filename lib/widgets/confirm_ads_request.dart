import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

Future<void> confirmAdRequest({
  required BuildContext context,
  required String actionType, // "accept" or "reject"
  required VoidCallback onConfirm,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final isDesktop = screenWidth > 600;
  final fontSize = isDesktop ? 18.0 : 16.0;
  final buttonFontSize = isDesktop ? 16.0 : 14.0;
  final paddingSize = isDesktop ? 24.0 : 16.0;

  String title = actionType == 'accept' ? 'تأكيد القبول' : 'تأكيد الرفض';
  String message = actionType == 'accept'
      ? 'هل أنت متأكد من قبول هذا الإعلان؟'
      : 'هل أنت متأكد من رفض هذا الإعلان؟';
  String confirmText = actionType == 'accept' ? 'قبول' : 'رفض';
  Color confirmColor = actionType == 'accept' ? primaryColor : primaryColor;

  final confirmed = await showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        contentPadding: EdgeInsets.all(paddingSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                color: primaryColor,
                fontFamily: mainFont,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: paddingSize),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize - 2,
                color: Colors.black87,
                fontFamily: mainFont,
              ),
            ),
            SizedBox(height: paddingSize * 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      color: Colors.grey[700],
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: paddingSize),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    confirmText,
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      color: confirmColor,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed == true) {
    onConfirm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actionType == 'accept'
              ? 'تم قبول الإعلان بنجاح'
              : 'تم رفض الإعلان بنجاح',
          style: TextStyle(
            fontFamily: mainFont,
            fontSize: isDesktop ? 14 : 14,
            color: const Color.fromARGB(255, 13, 13, 13),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 239, 235, 235),
      ),
    );
  }
}
