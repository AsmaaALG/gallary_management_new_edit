import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/main_screen.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:gallery_management/services/firestore_service.dart';

class PartnerManagementScreen extends StatefulWidget {
  final String galleryId;
  const PartnerManagementScreen({super.key, required this.galleryId});

  @override
  State<PartnerManagementScreen> createState() =>
      _PartnerManagementScreenState();
}

class _PartnerManagementScreenState extends State<PartnerManagementScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchCtl = TextEditingController();

  /* ---------- Dialog الإضافة / التعديل ---------- */
  Future<void> _showPartnerDialog({DocumentSnapshot? doc}) async {
    final nameCtl = TextEditingController(text: doc?['name'] ?? '');
    final imageCtl = TextEditingController(text: doc?['image'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 250, 230, 230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(doc == null ? 'إضافة شريك' : 'تعديل الشريك',
                style: const TextStyle(fontFamily: mainFont))),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtl, 'اسم الشريك'),
                const SizedBox(height: 10),
                _field(imageCtl, 'رابط الصورة'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(fontFamily: mainFont))),
          TextButton(
              onPressed: () async {
                if (nameCtl.text.trim().isEmpty || imageCtl.text.trim().isEmpty)
                  return;
                if (doc == null) {
                  await _fs.addPartner(
                      name: nameCtl.text.trim(),
                      imageUrl: imageCtl.text.trim(),
                      galleryId: widget.galleryId);
                } else {
                  await _fs.updatePartner(doc.id,
                      name: nameCtl.text.trim(),
                      imageUrl: imageCtl.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text(doc == null ? 'إضافة' : 'حفظ',
                  style: const TextStyle(
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor))),
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

  /* ---------- واجهة ---------- */
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getPartnersForGallery(widget.galleryId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // بناء قائمة MainCard
        final cards = snap.data!.docs.where((d) {
          final nm = d['name'].toString().toLowerCase();
          return nm.contains(_searchCtl.text.toLowerCase());
        }).map<MainCard>((d) {
          return MainCard(
            title: d['name'],
            buttons: [
              {
                'icon': Icons.edit,
                'action': () => _showPartnerDialog(doc: d),
              },
              {
                'icon': Icons.delete_rounded,
                'action': () => confirmDelete(context, () async {
                      await _fs.deleteDocument('partners', d.id);
                    })
              },
            ],
          );
        }).toList();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
                backgroundColor: primaryColor,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                onPressed: () => _showPartnerDialog()),
            body: MainScreen(
              title: 'التعديل على الشركاء',
              description:
                  'من هنا يمكنك إضافة أو تعديل أو حذف شركاء هذا المعرض',
              cards: cards,
              addScreen:
                  const SizedBox(), // لن يُستعمل لأننا نظهر حوار بدلاً من صفحة
            ),
          ),
        );
      },
    );
  }
}
