import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/control_panal.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // تهيئة قبل تشغيل Firebase

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 

  // قفل الشاشة على الوضع العمودي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // أثناء التحميل
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // المستخدم مسجّل دخول
            return const ControlPanel();
          } else {
            // المستخدم مسجّل خروج
            return SignInScreen();
          }
        },
      ),
    );
  }
}
