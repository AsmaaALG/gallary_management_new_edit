import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/user_session.dart';
import 'package:gallery_management/screens/control_panal.dart';
import 'package:gallery_management/services/auth.dart';
import 'package:gallery_management/widgets/custom_text_field.dart';

class SignInScreen extends StatefulWidget {
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showSpinner = false;

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    setState(() {
      showSpinner = true;
    });

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور')),
      );
      setState(() => showSpinner = false);
      return;
    }

    try {
      bool isValid = await Auth().signIn(emailController, passwordController);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('البريد الإلكتروني ليس مسجلاً كمسؤول')),
        );
        setState(() => showSpinner = false);
        return;
      }

      if (isValid) {
        UserSession.email = email;
        UserSession.password = pass;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ControlPanel()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء محاولة تسجيل الدخول: $e')),
      );
    } finally {
      setState(() => showSpinner = false);
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
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: isWideScreen ? 450 : double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isWideScreen
                  ? [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "مرحبا بك في لوحة تحكم المعارض",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: mainFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "إدارة معارضك تبدأ من هنا",
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),
                Image.asset(
                  'images/logo.png',
                  height: 140,
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  hintText: "البريد الإلكتروني",
                  controller: emailController,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  hintText: "كلمة المرور",
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 30),
                showSpinner
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 40),
                        ),
                        child: const Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            fontFamily: mainFont,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
