import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/main_screen.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String galleryName = 'المعرض';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGalleryName();
  }

  Future<void> loadGalleryName() async {
    final doc = await FirebaseFirestore.instance
        .collection('2')
        .doc(widget.galleryId)
        .get();
    final data = doc.data();
    setState(() {
      galleryName = data?['title'] ?? 'المعرض';
      isLoading = false;
    });
  }

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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (await canLaunchUrl(imgurUrl)) {
                      await launchUrl(imgurUrl,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'افتح Imgur لرفع صورة',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: mainFont,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
              if (nameCtl.text.trim().isEmpty || imageCtl.text.trim().isEmpty)
                return;

              if (doc == null) {
                await _fs.addPartner(
                  name: nameCtl.text.trim(),
                  imageUrl: imageCtl.text.trim(),
                  galleryId: widget.galleryId,
                );
              } else {
                await _fs.updatePartner(
                  doc.id,
                  name: nameCtl.text.trim(),
                  imageUrl: imageCtl.text.trim(),
                );
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

  /* ---------- واجهة ---------- */
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isLoading ? 'تحميل...' : galleryName,
            style: const TextStyle(
              fontFamily: mainFont,
              fontSize: 18,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showPartnerDialog(),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _fs.getPartnersForGallery(widget.galleryId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
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
                    'action': () => _showPartnerDialog(doc: d),
                  },
                  {
                    'icon': Icons.delete_rounded,
                    'action': () => confirmDelete(context, () async {
                          await _fs.deleteDocument('partners', d.id);
                        }),
                  },
                ],
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //const Text(
                  //'التعديل على الشركاء',
                  //style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: mainFont),
                  //),
                  const SizedBox(height: 8),
                  const Text(
                    'من هنا يمكنك إضافة أو تعديل أو حذف شركاء هذا المعرض',
                    style: TextStyle(fontFamily: mainFont),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: cards,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
