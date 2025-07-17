import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerManagementScreen2 extends StatefulWidget {
  final String galleryId;
  const PartnerManagementScreen2({super.key, required this.galleryId});

  @override
  State<PartnerManagementScreen2> createState() =>
      _PartnerManagementScreenState();
}

class _PartnerManagementScreenState extends State<PartnerManagementScreen2> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchCtl = TextEditingController();

  String? _galleryName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGalleryName();
  }

  Future<void> _fetchGalleryName() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('2')
        .doc(widget.galleryId)
        .get();

    if (snapshot.exists) {
      setState(() {
        _galleryName = snapshot.data()?['title'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _galleryName = 'اسم غير متوفر';
        _isLoading = false;
      });
    }
  }

  bool _isValidImageUrl(String url) {
    final RegExp regex =
        RegExp(r'^https?:\/\/.*\.(png|jpe?g|gif|bmp)', caseSensitive: false);
    return regex.hasMatch(url);
  }

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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'افتح Imgur لرفع صورة',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: mainFont, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                if (nameCtl.text.trim().isEmpty ||
                    imageCtl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى ملئ جميع الحقول')));
                  return;
                }
                if (!_isValidImageUrl(imageCtl.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال رابط صورة صحيح')),
                  );
                  return;
                }

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
              )),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getPartnersForGallery(widget.galleryId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

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
                    }),
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
              onPressed: () => _showPartnerDialog(),
            ),
            body: MainScreen(
              title: 'التعديل على الشركاء',
              description:
                  'من هنا يمكنك إضافة أو تعديل أو حذف شركاء هذا المعرض',
              cards: cards,
              galleryName: _galleryName ?? '', // <== هنا اسم المعرض بدون bold
            ),
          ),
        );
      },
    );
  }
}
