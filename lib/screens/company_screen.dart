import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/add_admin_screen.dart';
import 'package:gallery_management/screens/main_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('company').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          }

          final cards = snapshot.data!.docs.map((doc) {
            final documentId = doc.id;

            Future<void> delete() {
              return _firestoreService.deleteAdmin(doc.id);
            }

            return MainCard(
              title: doc['name'],
              buttons: [
                {
                  'icon': Icons.edit,
                  'action': () {
                    // _editAdminDialog(context, doc);
                  },
                },
                {
                  'icon': Icons.delete_rounded,
                  'action': () {
                    confirmDelete(context, () async {
                      await _firestoreService.deleteDocument(
                          'company', documentId);
                    });
                  },
                },
              ],
            );
          }).toList();

          return MainScreen(
            title: 'إدارة الشركات المنظمة',
            description:
                'من خلال هذه الواجهة يمكنك متابعة بيانات جميع الشركات المنظمة للمعارض',
            cards: cards,
            addScreen: AddAdminScreen(
              firestoreService: _firestoreService,
            ),
          );
        },
      ),
    );
  }
}
