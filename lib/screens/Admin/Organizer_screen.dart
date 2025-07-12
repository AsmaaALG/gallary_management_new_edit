import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/Admin/add_organizer_screen.dart';
import 'package:gallery_management/screens/Admin/edit_organizer_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class OrganizerScreen extends StatefulWidget {
  final String? companyId;

  const OrganizerScreen({super.key, this.companyId});

  @override
  State<OrganizerScreen> createState() => _OrganizerScreenState();
}

class _OrganizerScreenState extends State<OrganizerScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    // حدد الاستعلام بناءً على وجود companyId
    final stream = widget.companyId != null
        ? FirebaseFirestore.instance
            .collection('Organizer')
            .where('company_id', isEqualTo: widget.companyId)
            .snapshots()
        : FirebaseFirestore.instance.collection('Organizer').snapshots();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          }

          final docs = snapshot.data!.docs;

          final cards = docs.map((doc) {
            final documentId = doc.id;

            return MainCard(
              title: doc['email'],
              buttons: [
                {
                  'icon': Icons.edit,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditOrganizerScreen(
                          organizerId: documentId,
                        ),
                      ),
                    );
                  },
                },
                {
                  'icon': Icons.delete_rounded,
                  'action': () {
                    confirmDelete(context, () async {
                      await _firestoreService.deleteDocument(
                          'Organizer', documentId);
                    });
                  },
                },
              ],
            );
          }).toList();

          // ✅ عرض الشاشة بنفس الشكل، وإظهار رسالة فقط لو مافيش منظمين
          return MainScreen(
            title: 'إدارة المنظمين',
            description:
                'من خلال هذه الواجهة يمكنك متابعة بيانات جميع المنظمين',
            cards: cards.isNotEmpty ? cards : [], // نمرر قائمة فاضية
            addScreen: const AddOrganizerScreen(),
          );
          ;
        },
      ),
    );
  }
}
