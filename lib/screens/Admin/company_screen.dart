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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.grey,
      ),
    );
  }

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
              final name = nameCtl.text.trim();
              final number = commercialNumberCtl.text.trim();

              if (name.isEmpty || number.isEmpty) {
                _showSnackBar('يرجى تعبئة جميع الحقول');
                return;
              }

              if (!RegExp(r'^\d+$').hasMatch(number)) {
                _showSnackBar('الرقم التجاري يجب أن يحتوي على أرقام فقط');
                return;
              }

              final companies =
                  await FirebaseFirestore.instance.collection('company').get();

              final isDuplicate = companies.docs.any((d) {
                final isSameDoc = doc != null && d.id == doc.id;
                final sameName = d['name'].toString().trim() == name;
                final sameNumber =
                    d['Commercial number'].toString().trim() == number;
                return !isSameDoc && (sameName || sameNumber);
              });

              if (isDuplicate) {
                _showSnackBar('اسم الشركة أو الرقم التجاري مستخدم مسبقًا');
                return;
              }

              if (doc == null) {
                await FirebaseFirestore.instance.collection('company').add({
                  'name': name,
                  'Commercial number': number,
                });
              } else {
                await FirebaseFirestore.instance
                    .collection('company')
                    .doc(doc.id)
                    .update({
                  'name': name,
                  'Commercial number': number,
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

  Future<bool> isCompanyUsed(String companyId) async {
    final galleries = await FirebaseFirestore.instance
        .collection('2')
        .where('company_id', isEqualTo: companyId)
        .limit(1)
        .get();

    final ads = await FirebaseFirestore.instance
        .collection('ads')
        .where('company_id', isEqualTo: companyId)
        .limit(1)
        .get();

    return galleries.docs.isNotEmpty || ads.docs.isNotEmpty;
  }

  Future<bool> deleteCompanyWithOrganizers(String companyId) async {
    final used = await isCompanyUsed(companyId);
    if (used) {
      _showSnackBar('لا يمكن حذف الشركة لأنها مستخدمة في معارض أو إعلانات');
      return false;
    }

    final organizers = await FirebaseFirestore.instance
        .collection('Organizer')
        .where('company_id', isEqualTo: companyId)
        .get();

    for (var org in organizers.docs) {
      await FirebaseFirestore.instance
          .collection('Organizer')
          .doc(org.id)
          .delete();
    }

    await _firestoreService.deleteDocument('company', companyId);
    _showSnackBar('تم حذف الشركة');
    return true;
  }

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
                  'icon': Icons.group,
                  'action': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrganizerScreen(companyId: doc.id),
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
                  'action': () => showDeleteConfirmationDialog(
                        context: context,
                        content: 'هل تريد حذف هذه الشركة؟',
                        onConfirm: () => deleteCompanyWithOrganizers(doc.id),
                      ),
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
            ),
          );
        },
      ),
    );
  }

  Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required Future<bool> Function() onConfirm,
    String title = 'تأكيد الحذف',
    String content = 'هل أنت متأكد أنك تريد الحذف؟',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );

    // if (confirmed == true) {
    //   final success = await onConfirm();
    //   if (!success) {
    //   }
    // }
  }
}
