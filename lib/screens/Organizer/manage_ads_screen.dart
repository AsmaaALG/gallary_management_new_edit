import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/Organizer/booking_requests_screen.dart';
import 'package:gallery_management/screens/Organizer/edit_ads_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/screens/Organizer/MyAdsRequestsScreen.dart';
import 'package:gallery_management/screens/Organizer/add_ads_screen2.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class ManageAdsScreen extends StatefulWidget {
  final String organizerCompanyId;

  const ManageAdsScreen({super.key, required this.organizerCompanyId});

  @override
  State<ManageAdsScreen> createState() => _ManageGalleriesScreenState();
}

class _ManageGalleriesScreenState extends State<ManageAdsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ads').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                    'لا يمكن تحميل البيانات. يرجى التحقق من الاتصال بالإنترنت.'),
              ),
            );
          }

          final filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['company_id'] == widget.organizerCompanyId;
          }).toList();

          final cards = filteredDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final documentId = doc.id;

            return MainCard(
              title: data['title'] ?? 'بدون عنوان',
              buttons: [
                {
                  'icon': Icons.edit,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAdsScreen(adId: documentId),
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
                            BookingRequestsScreen(adId: documentId, adname: data['title'],),
                      ),
                    );
                  },
                },
              ],
            );
          }).toList();

          return MainScreen(
            title: 'إدارة الإعلانات',
            description: filteredDocs.isEmpty
                ? 'لا توجد إعلانات حالياً. يمكنك البدء بإضافة إعلان جديد.'
                : 'يمكنك من خلال هذه الواجهة إدارة جميع الإعلانات.',
            cards: cards,
            addScreen: AddAdsScreen2(
              companyId: widget.organizerCompanyId,
            ),
            requests: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyAdsRequestsScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.list_alt_rounded,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
