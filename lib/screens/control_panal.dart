import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/admin_management_screen.dart';
import 'package:gallery_management/screens/admin_management_screen2.dart';
import 'package:gallery_management/screens/ads_screen.dart';
import 'package:gallery_management/screens/ads_screen2.dart';
import 'package:gallery_management/screens/gallery_management_screen.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/auth.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  User? _user;

  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // تعيين اتجاه النص إلى RTL
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          // title: Image.asset("images/logo.png"),
          title: Image.asset(
            "images/white_logo.png",
            height: 800,
            width: 80,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _user != null
                    ? _user!.email ?? ''
                    : 'البريد الإلكتروني غير متوفر',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    color: Colors.white, fontSize: 12, fontFamily: mainFont),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة التحكم',
                style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    fontFamily: mainFont,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'من خلال هذه الواجهة يمكنك متابعة أحدث الطلبات والإعلانات الجديدة',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: mainFont,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    AdminCard(
                      title: 'إدارة المسؤولين',
                      description:
                          'يمكنك إدارة المسؤولين ومتابعة جميع بياناتهم.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminManagementScreen2(),
                        ),
                      ),
                    ),
                    AdminCard(
                      title: 'إدارة المعارض',
                      description:
                          'يمكنك إدارة المعارض لاضافة وتعجيل وحذف اي من المعارض .',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GalleryManagementScreen()),
                      ),
                    ),
                    AdminCard(
                      title: 'إدارة الإعلانات',
                      description:
                          'يمكنك إدارة الإعلانات والترويج للمعارض التي ستقام قريبا ',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdsScreen2()),
                      ),
                    ),
                    AdminCard(
                      title: 'إدارة طلبات حجز مساحة',
                      description: 'يمكنك إدارة طلبات حجز مساحة داخل المعارض.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GalleryManagementScreen()),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                        onPressed: () {
                          Auth().signOut(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    SignInScreen()), // تأكد من توجيه المستخدم إلى شاشة تسجيل الدخول
                          );
                        },
                        child: Text(
                          "تسجيل الخروج",
                          style: TextStyle(
                              fontFamily: mainFont,
                              color: primaryColor,
                              fontWeight: FontWeight.bold),
                        ))
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

class AdminCard extends StatelessWidget {
  final String title;
  final String description; // إضافة وصف
  final VoidCallback onTap;

  const AdminCard(
      {required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: mainFont,
                color: primaryColor), // استخدام mainFont
          ),
        ),
        subtitle: Text(
          description,
          style:
              TextStyle(fontSize: 14, fontFamily: mainFont), // استخدام mainFont
        ),
        onTap: onTap,
      ),
    );
  }
}
