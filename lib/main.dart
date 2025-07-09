import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/control_panal%20(2).dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/screens/Organizer/organizer_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyApp({super.key});

  // ✅ التحقق من مكان وجود UID في جدول admin أو Organizer
  Future<String?> checkUserRole(String uid) async {
    final adminDoc =
        await FirebaseFirestore.instance.collection('admin').doc(uid).get();

    if (adminDoc.exists) return 'admin';

    final organizerDoc =
        await FirebaseFirestore.instance.collection('Organizer').doc(uid).get();

    if (organizerDoc.exists) return 'organizer';

    return null;
  }

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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final uid = snapshot.data!.uid;

            return FutureBuilder<String?>(
              future: checkUserRole(uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (roleSnapshot.hasData) {
                  if (roleSnapshot.data == 'admin') {
                    return const ControlPanel();
                  } else if (roleSnapshot.data == 'organizer') {
                    return OrganizerDashboardScreen(userId: uid);
                  } else {
                    return const Scaffold(
                      body: Center(child: Text('المستخدم غير مصرح له')),
                    );
                  }
                } else {
                  return const Scaffold(
                    body: Center(child: Text('تعذر تحديد نوع المستخدم')),
                  );
                }
              },
            );
          } else {
            return SignInScreen();
          }
        },
      ),
    );
  }
}
