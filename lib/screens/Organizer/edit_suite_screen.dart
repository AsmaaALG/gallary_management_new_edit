import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/pick_and_up_load_image.dart';
import 'package:gallery_management/screens/Admin/suite_images_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EditSuiteScreen extends StatefulWidget {
  final String suiteId;
  final String galleryId;

  const EditSuiteScreen({
    super.key,
    required this.suiteId,
    required this.galleryId,
  });

  @override
  State<EditSuiteScreen> createState() => _EditSuiteScreenState();
}

class _EditSuiteScreenState extends State<EditSuiteScreen> {
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _imageCtl = TextEditingController();
  final _titleCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _sizeCtl = TextEditingController();
  String? uploadedImageUrl;

  bool isLoading = true;
  bool _isUploading = false;

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

  bool _isValidImageUrl(String url) {
    final RegExp regex =
        RegExp(r'^https?:\/\/.*\.(png|jpe?g|gif|bmp)', caseSensitive: false);
    return regex.hasMatch(url);
  }

  Future<bool> validateInputs() async {
    final title = _titleCtl.text.trim();
    final priceText = _priceCtl.text.trim();
    final sizeText = _sizeCtl.text.trim();

    if (title.isNotEmpty) {
      final validRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
      if (!validRegex.hasMatch(title)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('العنوان يجب أن يحتوي فقط على حروف إنجليزية وأرقام'),
          ),
        );
        return false;
      }

      // تحقق من تكرار العنوان داخل نفس المعرض فقط
      final snapshot = await FirebaseFirestore.instance
          .collection('suite')
          .where('gallery id', isEqualTo: widget.galleryId)
          .get();

      final isDuplicate = snapshot.docs.any((doc) {
        final existingId = doc.id;
        final existingTitle =
            (doc.data()['title on map'] ?? '').toString().toLowerCase();
        return existingId != widget.suiteId &&
            existingTitle == title.toLowerCase(); // 🔹 استثناء الجناح الحالي
      });

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'العنوان "$title" مستخدم بالفعل داخل هذا المعرض، يرجى اختيار عنوان آخر'),
          ),
        );
        return false;
      }
    }

    if (_imageCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة')),
      );
      return false;
    }

    if (priceText.isNotEmpty) {
      final price = double.tryParse(priceText);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال سعر صحيح')),
        );
        return false;
      }
    }

    if (sizeText.isNotEmpty) {
      final size = double.tryParse(sizeText);
      if (size == null || size <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال مساحة صحيحة')),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> updateSuite() async {
    final isValid = await validateInputs();
    if (!isValid) return;

    try {
      final Map<String, dynamic> suiteData = {
        'gallery id': widget.galleryId,
        'name': _nameCtl.text.trim(),
        'description': _descCtl.text.trim(),
        'main image': _imageCtl.text.trim(),
        'title on map': _titleCtl.text.trim(),
        'price': _priceCtl.text.trim(),
        'size': _sizeCtl.text.trim()
      };

      final title = _titleCtl.text.trim();
      if (title.isNotEmpty) suiteData['title on map'] = title;

      final priceText = _priceCtl.text.trim();
      if (priceText.isNotEmpty) {
        suiteData['price'] = double.parse(priceText);
      }

      final sizeText = _sizeCtl.text.trim();
      if (sizeText.isNotEmpty) {
        suiteData['size'] = double.parse(sizeText);
      }

      await FirebaseFirestore.instance
          .collection('suite')
          .doc(widget.suiteId)
          .update(suiteData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعديل بيانات الجناح بنجاح'),
          backgroundColor: Color.fromARGB(255, 123, 123, 123),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: mainFont,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide:
                  const BorderSide(color: Color.fromARGB(255, 209, 167, 181)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide:
                  const BorderSide(color: Color.fromARGB(255, 218, 142, 170)),
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
            'تعديل بيانات الجناح',
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
                  vertical: 20,
                  horizontal: isWideScreen ? 30 : 10,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "يمكنك من خلال هذه الواجهة تعديل بيانات الجناح عبر تعبئة الحقول التالية:",
                        style: TextStyle(fontFamily: mainFont, fontSize: 14),
                      ),
                      const SizedBox(height: 25),
                      buildTextField('اسم الجناح', _nameCtl),
                      buildTextField('وصف الجناح', _descCtl, maxLines: 5),
                      ElevatedButton(
                        onPressed: _isUploading
                            ? null 
                            : () async {
                                setState(() {
                                  _isUploading = true;
                                });

                                final imageUrl = await pickAndUploadImage(
                                  imgbbApiKey:
                                      '95daff58b10157f2de7ddd93301132e2',
                                );

                                if (imageUrl != null) {
                                  setState(() {
                                    uploadedImageUrl = imageUrl;
                                    _imageCtl.text = imageUrl;
                                  });
                                }

                                setState(() {
                                  _isUploading = false;
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _isUploading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    'اختيار صورة الجناح',
                                    style: TextStyle(
                                        fontFamily: mainFont, fontSize: 10),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                      buildTextField('العنوان على الخريطة', _titleCtl),
                      buildTextField('السعر', _priceCtl,
                          keyboardType: TextInputType.number),
                      buildTextField('المساحة (م²)', _sizeCtl,
                          keyboardType: TextInputType.number),
                      // ElevatedButton(
                      //   onPressed: () async {
                      //     const imgurUrl = 'https://imgur.com/upload';
                      //     if (await canLaunch(imgurUrl)) {
                      //       await launch(imgurUrl);
                      //     }
                      //   },
                      //   child: const Text('افتح Imgur لرفع صورة'),
                      // ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 15,
                        runSpacing: 10,
                        alignment: isWeb(context)
                            ? WrapAlignment.center
                            : WrapAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: updateSuite,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text(
                              'تعديل',
                              style: TextStyle(
                                  fontFamily: mainFont, color: Colors.black),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SuiteImageScreen(suiteId: widget.suiteId),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text(
                              'عرض صور الجناح',
                              style: TextStyle(
                                  fontFamily: mainFont, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
