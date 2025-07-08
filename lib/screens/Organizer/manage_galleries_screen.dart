import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/GalleryStatistic_screen.dart';
import 'package:gallery_management/screens/Admin/add_gallery_screen.dart';
import 'package:gallery_management/screens/Admin/gallery_suite_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/screens/Admin/review_management_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class ManageGalleriesScreen extends StatefulWidget {
  final String organizerCompanyId;

  const ManageGalleriesScreen({super.key, required this.organizerCompanyId});

  @override
  State<ManageGalleriesScreen> createState() => _ManageGalleriesScreenState();
}

class _ManageGalleriesScreenState extends State<ManageGalleriesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('2').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          }

          final filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['company_id'] == widget.organizerCompanyId;
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(child: Text('لا توجد معارض تابعة لك.'));
          }

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
                        builder: (context) =>
                            GallerySuiteScreen(galleryId: documentId),
                      ),
                    );
                  },
                },
                {
                  'icon': Icons.delete_rounded,
                  'action': () {
                    confirmDelete(context, () async {
                      await _firestoreService
                          .deleteGalleryAndRelatedData(documentId);
                    });
                  },
                },
                {
                  'icon': Icons.messenger_rounded,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewManagementScreen(
                          galleryId: documentId,
                        ),
                      ),
                    );
                  },
                },
                {
                  'icon': Icons.dashboard_rounded,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GalleryStatisticsScreen(galleryId: documentId),
                      ),
                    );
                  },
                },
              ],
            );
          }).toList();

          return MainScreen(
            title: 'إدارة المعارض',
            description: 'قم بإدارة المعارض الخاصة بشركتك من هنا.',
            cards: cards,
            addScreen: AddGalleryScreen(),
          );
        },
      ),
    );
  }
}
