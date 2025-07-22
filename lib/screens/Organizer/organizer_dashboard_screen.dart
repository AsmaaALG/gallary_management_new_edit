import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/route_observer.dart';
import 'package:gallery_management/screens/Organizer/manage_ads_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'manage_galleries_screen.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/auth.dart';

// تأكد أن هذا متوفر في main.dart
// final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class OrganizerDashboardScreen extends StatefulWidget {
  final String userId;

  const OrganizerDashboardScreen({super.key, required this.userId});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    // أول مرة يتم الدخول للشاشة
    FirestoreService().convertAdsToGalleries();
  }

  @override
  void didPopNext() {
    // عند الرجوع من شاشة فرعية إلى هذه الشاشة
    FirestoreService().convertAdsToGalleries();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final String currentUserId = widget.userId;

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
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Organizer')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('لم يتم العثور على بيانات المنظم'));
            }

            final organizerData = snapshot.data!.data() as Map<String, dynamic>;
            final companyId = organizerData['company_id'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('company')
                  .doc(companyId)
                  .get(),
              builder: (context, companySnapshot) {
                if (companySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!companySnapshot.hasData || !companySnapshot.data!.exists) {
                  return Center(child: Text('لم يتم العثور على بيانات الشركة'));
                }

                final companyData =
                    companySnapshot.data!.data() as Map<String, dynamic>;
                final companyName = companyData['name'] ?? '---';

                return Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 20, horizontal: isWideScreen ? 30 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لوحة تحكم المنظمين ل$companyName',
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryColor,
                          fontFamily: mainFont,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
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
                                  'يمكنك إدارة المعارض لاضافة وتعديل أي من المعارض.',
                              isEnabled: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageGalleriesScreen(
                                      organizerCompanyId: companyId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AdminCard(
                              title: 'إدارة الإعلانات',
                              description:
                                  'يمكنك إدارة الإعلانات والترويج للمعارض بالإضافة إلى إدارة طلبات الحجز لكل معرض.',
                              isEnabled: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ManageAdsScreen(
                                          organizerCompanyId: companyId)),
                                );
                              },
                            ),
                            SizedBox(height: 20),
                            TextButton(
                              onPressed: () {
                                Auth().signOut(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignInScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "تسجيل الخروج",
                                style: TextStyle(
                                  fontFamily: mainFont,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
    super.key,
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
