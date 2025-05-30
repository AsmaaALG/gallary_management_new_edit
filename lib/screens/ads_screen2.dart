import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/add_ads_screen.dart';
import 'package:gallery_management/screens/booking_requests_screen.dart';
import 'package:gallery_management/screens/edit_ads_screen.dart';
import 'package:gallery_management/screens/main_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class AdsScreen2 extends StatefulWidget {
  const AdsScreen2({super.key});

  @override
  State<AdsScreen2> createState() => _AdsScreen2State();
}

class _AdsScreen2State extends State<AdsScreen2> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _galleries = [];

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
  }

  // دالة لجلب المعارض من Firebase
  Future<void> _fetchGalleries() async {
    List<Map<String, dynamic>> galleries =
        await _firestoreService.getAllData('2');
    setState(() {
      _galleries = galleries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ads').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ أثناء جلب البيانات'));
              }

              // تحويل البيانات إلى قائمة من MainCard
              final cards = snapshot.data!.docs.map((doc) {
                final documentId = doc.id; // الحصول على معرف المستند

                return MainCard(
                  title: doc['title'], // تأكد من وجود حقل 'title'
                  buttons: [
                    {
                      'icon': Icons.edit,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditAdsScreen(adId: documentId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': Icons.delete_rounded,
                      'action': () {
                       confirmDelete(context, () async {
                      await _firestoreService.deleteDocument('ads', documentId);
                    });
                      },
                    },
                    {
                      'icon': Icons.list_alt,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingRequestsScreen(adId: documentId),
                          ),
                        );
                      },
                    },
                  ],
                );
              }).toList();

              return MainScreen(
                title: 'إدارة الإعلانات',
                description:
                    'يمكنك من خلال هذه الواجهة بإدارة جميع الإعلانات  .',
                cards: cards,
                addScreen: AddAdsScreen(),
              );
            }));
  }
}
