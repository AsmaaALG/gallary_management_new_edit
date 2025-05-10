import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/screens/sign_up_screen.dart';

class SignInUpScreen extends StatefulWidget {
  @override
  _SignInUpScreenState createState() => _SignInUpScreenState();
}

class _SignInUpScreenState extends State<SignInUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Column(
              children: [
                Text(
                  "مرحبا يك في لوحة تحكم المعارض",
                  style: TextStyle(
                      fontFamily: mainFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "ادارة معارضك تبدأ من هنا",
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Image.asset(
              'images/logo.png', // استبدل بمسار الشعار الفعلي
              height: 170,
            ),
            Column(
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: BorderSide(color: cardBackground),
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  ),
                  child: Text("تسجيل الدخول",
                      style:
                          TextStyle(fontFamily: mainFont, color: Colors.white)),
                ),
                SizedBox(
                  height: 15,
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignUpScreen(), // التنقل إلى صفحة التسجيل
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: BorderSide(color: cardBackground),
                    padding: EdgeInsets.symmetric(horizontal: 55, vertical: 15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("إنشاء حساب جديد",
                        style: TextStyle(
                            fontFamily: mainFont, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
