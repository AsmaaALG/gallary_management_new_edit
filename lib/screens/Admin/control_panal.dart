import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/admin_management_screen2.dart';
import 'package:gallery_management/screens/Admin/ads_screen2.dart';
import 'package:gallery_management/screens/Admin/gallery_management_screen.dart';
import 'package:gallery_management/screens/Admin/organizing%20_company_screen.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/auth.dart';
import 'package:gallery_management/screens/Admin/dashboard_screen.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  User? _user;
  int _userState = 0; // 0 = لا يملك صلاحيات, 1 = يملك صلاحيات

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(_user!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userState = userDoc.get('state') ?? 0;
        });
      }
    }
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ليس لديك صلاحيات لإدارة المسؤولين',
          style: TextStyle(fontFamily: mainFont),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
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
          padding: EdgeInsets.symmetric(
              vertical: 30, horizontal: isWideScreen ? 250 : 30),
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
                      onTap: _userState == 1
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminManagementScreen2(),
                                ),
                              )
                          : _showPermissionDeniedMessage,
                      isEnabled: _userState == 1,
                    ),
                    AdminCard(
                      title: 'إدارة الشركات المنظمة',
                      description:
                          'يمكنك إدارة المشركات المنظمة والمنظمين التابعين لها',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrganizingCompanyScreen(),
                        ),
                      ),
                      isEnabled: true,
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
                      isEnabled: true,
                    ),
                    AdminCard(
                      title: 'إدارة الإعلانات',
                      description:
                          'يمكنك إدارة الإعلانات والترويج للمعارض التي ستقام قريبا ',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdsScreen2()),
                      ),
                      isEnabled: true,
                    ),
                    AdminCard(
                      title: 'التقارير والإحصائيات',
                      description:
                          'عرض تقارير تفصيلية حول المعارض، المستخدمين، الحجوزات والمفضلات.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DashboardScreen()),
                      ),
                      isEnabled: true,
                    ),
                    SizedBox(height: 20),
                    TextButton(
                        onPressed: () {
                          Auth().signOut(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignInScreen()),
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
  final String description;
  final VoidCallback onTap;
  final bool isEnabled;

  const AdminCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      color: isEnabled ? null : Colors.grey[200],
      child: ListTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: mainFont,
              color: isEnabled ? primaryColor : Colors.grey,
            ),
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            fontFamily: mainFont,
            color: isEnabled ? null : Colors.grey,
          ),
        ),
        onTap: isEnabled ? onTap : null,
      ),
    );
  }
}
