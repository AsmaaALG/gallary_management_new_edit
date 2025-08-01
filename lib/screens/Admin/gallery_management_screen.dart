import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/Admin/GalleryStatistic_screen.dart';
import 'package:gallery_management/screens/Admin/gallery_suite_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/screens/Admin/review_management_screen.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:gallery_management/services/firestore_service.dart';

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() =>
      _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen> {
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
            stream: FirebaseFirestore.instance.collection('2').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ أثناء جلب البيانات'));
              }

              final cards = snapshot.data!.docs.map((doc) {
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
                              builder: (_) => GalleryStatisticsScreen(
                                  galleryId: documentId)),
                        );
                      },
                    },
                  ],
                );
              }).toList();

              return MainScreen(
                title: 'إدارة المعارض',
                description: 'قم بإدارة المعارض من هنا.',
                cards: cards,
              );
            }));
  }
}
