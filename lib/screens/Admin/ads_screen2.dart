import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/trush/add_ads_screen.dart';
import 'package:gallery_management/screens/Organizer/booking_requests_screen.dart';
import 'package:gallery_management/screens/Organizer/edit_ads_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/screens/Admin/view_ads_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:intl/intl.dart' as intl;

class AdsScreen2 extends StatefulWidget {
  const AdsScreen2({super.key});

  @override
  State<AdsScreen2> createState() => _AdsScreen2State();
}

class _AdsScreen2State extends State<AdsScreen2> {
  final FirestoreService _firestoreService = FirestoreService();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ads').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          }

          final now = DateTime.now();

          final cards = snapshot.data!.docs.where((doc) {
            return true;
          }).map((doc) {
            final documentId = doc.id;

            return MainCard(
              title: doc['title'],
              buttons: [
                {
                  'icon': Icons.visibility,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ViewAdsDataScreen(galleryId: documentId),
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
              ],
            );
          }).toList();

          return MainScreen(
            title: 'إدارة الإعلانات',
            description: 'يمكنك من خلال هذه الواجهة إدارة جميع الإعلانات.',
            cards: cards,
          );
        },
      ),
    );
  }
}
