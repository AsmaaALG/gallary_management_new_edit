import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/auth.dart';

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

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
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 30, horizontal: isWideScreen ? 250 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة تحكم المنظمين',
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
                        title: 'إدارة المعارض',
                        description:
                            'يمكنك إدارة المعارض لاضافة وتعديل اي من المعارض .',
                        isEnabled: true,
                        onTap: () {},
                      ),
                      AdminCard(
                        title: 'إدارة الإعلانات',
                        description:
                            'يمكنك إدارة الإعلانات والترويج للمعارض التي ستقام قريبا بالاضافة لادارة طلبات الحجز لكل معرض',
                        isEnabled: true,
                        onTap: () {},
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
        ));
    ;
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
