import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/Admin/add_admin_screen.dart';
import 'package:gallery_management/screens/Admin/add_organizer_screen.dart';
import 'package:gallery_management/screens/Admin/edit_organizer_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class OrganizerScreen extends StatefulWidget {
  const OrganizerScreen({super.key});

  @override
  State<OrganizerScreen> createState() => _OrganizerScreenState();
}

class _OrganizerScreenState extends State<OrganizerScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Organizer').snapshots(),
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
              title: doc['email'],
              buttons: [
                {
                  'icon': Icons.edit,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditOrganizerScreen(organizerId: documentId),
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

          return MainScreen(
              title: 'إدارة المنظمين',
              description:
                  'من خلال هذه الواجهة يمكنك متابعة بيانات جميع المنظمين',
              cards: cards,
              addScreen: AddOrganizerScreen());
        },
      ),
    );
  }
}
