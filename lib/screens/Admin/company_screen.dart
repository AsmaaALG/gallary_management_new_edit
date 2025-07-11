import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:gallery_management/screens/Admin/Organizer_screen.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _showCompanyDialog({DocumentSnapshot? doc}) async {
    final nameCtl = TextEditingController(text: doc?['name'] ?? '');
    final commercialNumberCtl =
        TextEditingController(text: doc?['Commercial number'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 250, 230, 230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(doc == null ? 'إضافة شركة' : 'تعديل الشركة',
              style: const TextStyle(fontFamily: mainFont)),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 260,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameCtl, 'اسم الشركة'),
                  const SizedBox(height: 10),
                  _field(commercialNumberCtl, 'الرقم التجاري'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: mainFont)),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtl.text.trim().isEmpty ||
                  commercialNumberCtl.text.trim().isEmpty) return;

              if (doc == null) {
                // إضافة شركة جديدة
                await FirebaseFirestore.instance.collection('company').add({
                  'name': nameCtl.text.trim(),
                  'Commercial number': commercialNumberCtl.text.trim(),
                });
              } else {
                // تحديث الشركة
                await FirebaseFirestore.instance
                    .collection('company')
                    .doc(doc.id)
                    .update({
                  'name': nameCtl.text.trim(),
                  'Commercial number': commercialNumberCtl.text.trim(),
                });
              }

              Navigator.pop(context);
            },
            child: Text(
              doc == null ? 'إضافة' : 'حفظ',
              style: const TextStyle(
                fontFamily: mainFont,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('company').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          }

          final cards = snapshot.data!.docs.map((doc) {
            return MainCard(
              title: doc['name'],
              buttons: [
                {
                  'icon': Icons.group, // ← أيقونة الأشخاص
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrganizerScreen(
                          companyId: doc.id,
                          //  companyName: doc['name'],
                        ),
                      ),
                    );
                  },
                },
                {
                  'icon': Icons.edit,
                  'action': () => _showCompanyDialog(doc: doc),
                },
                {
                  'icon': Icons.delete_rounded,
                  'action': () => confirmDelete(context, () async {
                        await _firestoreService.deleteDocument(
                            'company', doc.id);
                      }),
                },
              ],
            );
          }).toList();

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              backgroundColor: primaryColor,
              onPressed: () => _showCompanyDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: MainScreen(
              title: 'إدارة الشركات المنظمة',
              description:
                  'من خلال هذه الواجهة يمكنك متابعة بيانات جميع الشركات المنظمة للمعارض',
              cards: cards,
              addScreen: const SizedBox(), // غير مستخدم الآن
            ),
          );
        },
      ),
    );
  }
}
