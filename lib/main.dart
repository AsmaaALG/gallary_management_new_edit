import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/control_panal.dart';
import 'package:gallery_management/screens/signInUp_screen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // المستخدم في Flutter يتم تهيئتها قبل بدء التطبيق، وهو أمر ضروري قبل استخدام أي خدمات غير متزامنة مثل Firebase.
  await Firebase.initializeApp(); //تهيئة
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          useMaterial3: true,
        ),
        home: _auth.currentUser != null ? ControlPanel() : SignInUpScreen());
  }
}
