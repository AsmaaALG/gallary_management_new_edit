import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

class StatCard extends StatelessWidget {
  // تعريف المتغيرات المستخدمة في بطاقة الإحصائيات
  final String title; // عنوان البطاقة
  final int value; // القيمة المعروضة في البطاقة
  final IconData icon; // الأيقونة المرتبطة بالبطاقة
  final Color color; // لون الأيقونة والنص

  // المُنشئ الخاص بالبطاقة
  StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.all(6),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 25.0 : 16.0, // padding أفقي حسب نوع الجهاز
          vertical: isDesktop ? 15.0 : 16.0, // padding رأسي حسب نوع الجهاز
        ),
        child: Column(
<<<<<<< HEAD
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
=======
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
>>>>>>> 3154b310d3fa08530398d206f695ca211a4d9475
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
<<<<<<< HEAD
                      fontSize: isDesktop ? 18 : 13,
=======
                      fontSize: isDesktop ? 18 : 16,
>>>>>>> 3154b310d3fa08530398d206f695ca211a4d9475
                      color: primaryColor,
                      fontFamily: mainFont,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // إضافة نقاط إذا كان النص طويلاً
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: isDesktop ? 40 : 28,
                ),
              ],
            ),
            SizedBox(
                height:
                    isDesktop ? 20 : 8), // المسافة بين الصفين حسب نوع الجهاز
            Text(
              value.toString(), // عرض القيمة كنص
              style: TextStyle(
                fontSize: isDesktop ? 34 : 28,
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
