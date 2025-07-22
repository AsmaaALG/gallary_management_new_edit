import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/viewSuitePhoto_screen.dart';

class ViewSuiteDataScreen extends StatefulWidget {
  final String suiteId;
  final String galleryId;

  const ViewSuiteDataScreen({
    super.key,
    required this.suiteId,
    required this.galleryId,
  });

  @override
  State<ViewSuiteDataScreen> createState() => _ViewSuiteDataScreenState();
}

class _ViewSuiteDataScreenState extends State<ViewSuiteDataScreen> {
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _imageCtl = TextEditingController();
  final _titleCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _sizeCtl = TextEditingController();

  bool isLoading = true;
  bool isWeb(BuildContext context) => MediaQuery.of(context).size.width > 600;

  @override
  void initState() {
    super.initState();
    fetchSuiteData();
  }

  Future<void> fetchSuiteData() async {
    final doc = await FirebaseFirestore.instance
        .collection('suite')
        .doc(widget.suiteId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameCtl.text = data['name'] ?? '';
      _descCtl.text = data['description'] ?? '';
      _imageCtl.text = data['main image'] ?? '';
      _titleCtl.text = data['title on map'] ?? '';
      _priceCtl.text = data['price']?.toString() ?? '';
      _sizeCtl.text = data['size']?.toString() ?? '';
    }
    setState(() => isLoading = false);
  }

  Widget buildDisplayField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: mainFont,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            value.isNotEmpty ? value : 'غير متوفر',
            style: const TextStyle(
              fontFamily: mainFont,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'عرض بيانات الجناح',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white),
          ),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 30, horizontal: isWideScreen ? 250 : 30),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildDisplayField('اسم الجناح', _nameCtl.text),
                      buildDisplayField('وصف الجناح', _descCtl.text),
                      // صورة الجناح
                      if (_imageCtl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'صورة الجناح',
                          style: TextStyle(
                            fontFamily: mainFont,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageCtl.text,
                            height: 400,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('تعذر تحميل الصورة',
                                  style: TextStyle(color: Colors.red));
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                      ] else ...[
                        buildDisplayField('صورة الجناح', 'غير متوفر'),
                      ],

                      buildDisplayField('العنوان على الخريطة', _titleCtl.text),
                      buildDisplayField('السعر', _priceCtl.text),
                      buildDisplayField('المساحة (م²)', _sizeCtl.text),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewSuitePhotoScreen(
                                    suiteId: widget.suiteId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text(
                            'عرض صور الجناح',
                            style: TextStyle(
                                fontFamily: mainFont, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
