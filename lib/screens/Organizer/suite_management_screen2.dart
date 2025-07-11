import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/screens/Organizer/edit_suite_screen.dart';
import 'package:gallery_management/screens/Organizer/add_suite_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuiteManagementScreen2 extends StatefulWidget {
  final String galleryId;
  final String? galleryName;

  const SuiteManagementScreen2({
    super.key,
    required this.galleryId,
    this.galleryName,
  });

  @override
  State<SuiteManagementScreen2> createState() => _SuiteManagementScreenState();
}

class _SuiteManagementScreenState extends State<SuiteManagementScreen2> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchCtl = TextEditingController();

  String? _galleryName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGalleryName();
  }

  Future<void> _initGalleryName() async {
    if (widget.galleryName != null) {
      setState(() {
        _galleryName = widget.galleryName;
        _isLoading = false;
      });
    } else {
      final snapshot = await FirebaseFirestore.instance
          .collection('2')
          .doc(widget.galleryId)
          .get();
      setState(() {
        _galleryName = snapshot.data()?['title'] ?? 'اسم غير متوفر';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getSuitesForGallery(widget.galleryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final cards = snapshot.data!.docs.where((doc) {
          final name = doc['name'].toString().toLowerCase();
          return name.contains(_searchCtl.text.toLowerCase());
        }).map<MainCard>((doc) {
          return MainCard(
            title: doc['name'],
            buttons: [
              {
                'icon': Icons.edit,
                'action': () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditSuiteScreen(
                          suiteId: doc.id,
                          galleryId: widget.galleryId,
                        ),
                      ),
                    ),
                'heroTag': 'edit_suite_${doc.id}',
              },
              {
                'icon': Icons.delete,
                'action': () => confirmDelete(context, () async {
                      await _fs.deleteSuiteAndImages(doc.id);
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSuiteScreen(galleryId: widget.galleryId),
                ),
              ),
            ),
            body: MainScreen(
              title: 'التعديل على الأجنحة',
              description: 'قم بتعديل أجنحة المعرض أو إضافة أجنحة جديدة.',
              cards: cards,
              addScreen: const SizedBox(),
              galleryName: _galleryName ?? '',
            ),
          ),
        );
      },
    );
  }
}
