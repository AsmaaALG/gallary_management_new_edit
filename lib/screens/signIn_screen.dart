import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/control_panal.dart';
import 'package:gallery_management/screens/sign_up_screen.dart';
import 'package:gallery_management/services/auth.dart';
import 'package:gallery_management/widgets/custom_text_field.dart';
import 'package:gallery_management/widgets/social_button.dart';

class SignInScreen extends StatefulWidget {
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showSpinner = false;

  // دالة تسجيل الدخول
  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    setState(() {
      showSpinner = true;
    });

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور')),
      );
      setState(() {
        showSpinner = false;
      });
      return;
    }

    try {
      bool isValid = await Auth().signIn(emailController, passwordController);

      // البحث في مجموعة admin عن مستخدم بهذا البريد الإلكتروني
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('email',
              isEqualTo: email) // نفترض أن هناك حقل 'email' في المستندات
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('البريد الإلكتروني ليس مسجلاً كمسؤول')),
        );
        setState(() {
          showSpinner = false;
        });
        return;
      }

      // إذا وجدنا المستند، نتابع عملية تسجيل الدخول

      if (isValid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ControlPanel()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء محاولة تسجيل الدخول: $e')),
      );
    } finally {
      setState(() {
        showSpinner = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              const Text(
                "تسجيل الدخول",
                style: TextStyle(
                  fontFamily: mainFont,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      hintText: "البريد الإلكتروني",
                      controller: emailController,
                    ),
                    SizedBox(height: 10),
                    CustomTextField(
                      hintText: "كلمة المرور",
                      obscureText: true,
                      controller: passwordController,
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "هل نسيت كلمة المرور؟",
                          style: TextStyle(
                              fontFamily: mainFont,
                              color: primaryColor,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "التسجيل",
                        style: TextStyle(
                            fontFamily: mainFont,
                            color: cardBackground,
                            fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          "ليس لديك حساب؟ ",
                          style: TextStyle(fontFamily: mainFont, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpScreen()),
                            );
                          },
                          child: Text(
                            "سجل من هنا",
                            style: TextStyle(
                              fontFamily: mainFont,
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(thickness: 1, color: Colors.grey[400]),
                    SizedBox(height: 10),
                    SocialButton(
                      icon: FontAwesomeIcons.google,
                      text: "التسجيل باستخدام جوجل",
                      color: cardBackground,
                      textColor: Colors.black,
                      iconColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
