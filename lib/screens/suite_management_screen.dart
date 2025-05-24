import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/main_screen.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/screens/edit_suite_screen.dart';

class SuiteManagementScreen extends StatefulWidget {
  final String galleryId;
  const SuiteManagementScreen({super.key, required this.galleryId});

  @override
  State<SuiteManagementScreen> createState() => _SuiteManagementScreenState();
}

class _SuiteManagementScreenState extends State<SuiteManagementScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchCtl = TextEditingController();

  Future<void> _showSuiteDialog() async {
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final imageCtl = TextEditingController();

    bool nameError = false;
    bool descError = false;
    bool imageError = false;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 248, 243, 243),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Directionality(
              textDirection: TextDirection.rtl,
              child: Text('إضافة جناح', style: TextStyle(fontFamily: mainFont)),
            ),
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(nameCtl, 'اسم الجناح'),
                    if (nameError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('يرجى ملء هذا الحقل',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 10),
                    _field(descCtl, 'وصف الجناح'),
                    if (descError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('يرجى ملء هذا الحقل',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 10),
                    _field(imageCtl, 'رابط صورة الجناح'),
                    if (imageError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('يرجى ملء هذا الحقل',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('إلغاء', style: TextStyle(fontFamily: mainFont)),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    nameError = nameCtl.text.trim().isEmpty;
                    descError = descCtl.text.trim().isEmpty;
                    imageError = imageCtl.text.trim().isEmpty;
                  });

                  if (nameError || descError || imageError) return;

                  await _fs.addSuite(
                    name: nameCtl.text.trim(),
                    description: descCtl.text.trim(),
                    imageUrl: imageCtl.text.trim(),
                    galleryId: widget.galleryId,
                  );

                  Navigator.pop(context);
                },
                child: const Text(
                  'إضافة',
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getSuitesForGallery(widget.galleryId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final cards = snap.data!.docs.where((d) {
          final name = d['name'].toString().toLowerCase();
          return name.contains(_searchCtl.text.toLowerCase());
        }).map<MainCard>((d) {
          return MainCard(
            title: d['name'],
            buttons: [
              {
                'icon': Icons.edit,
                'action': () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSuiteScreen(suiteId: d.id),
                    ),
                  );
                },
              },
              {
                'icon': Icons.delete_rounded,
                'action': () => confirmDelete(context, 'suite', d.id),
              },
            ],
          );
        }).toList();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showSuiteDialog(),
            ),
            body: MainScreen(
              title: 'التعديل على الأجنحة',
              description:
                  'يمكنك من خلال هذه الواجهة تعديل الأجنحة داخل المعرض المحدد مسبقاً عبر تعبئة الحقول التالية',
              cards: cards,
              addScreen: const SizedBox(), // لن يُستعمل لأنه يوجد Dialog
            ),
          ),
        );
      },
    );
  }
}
