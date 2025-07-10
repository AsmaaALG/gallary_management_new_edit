import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/suite_images_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EditSuiteScreen extends StatefulWidget {
  final String suiteId;
  final String galleryId;

  const EditSuiteScreen(
      {super.key, required this.suiteId, required this.galleryId});

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

  Future<void> updateSuite() async {
    try {
      final suiteData = {
        'gallery id': widget.galleryId,
        'name': _nameCtl.text.trim(),
        'description': _descCtl.text.trim(),
        'main image': _imageCtl.text.trim(),
        'title on map': _titleCtl.text.trim(),
        'price': double.parse(_priceCtl.text.trim()),
        'size': double.parse(_sizeCtl.text.trim()),
      };

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
                    vertical: 30, horizontal: isWideScreen ? 250 : 30),
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
                      buildTextField('رابط صورة الجناح', _imageCtl),
                      buildTextField('العنوان على الخريطة', _titleCtl),
                      buildTextField('السعر', _priceCtl,
                          keyboardType: TextInputType.number),
                      buildTextField('المساحة (م²)', _sizeCtl,
                          keyboardType: TextInputType.number),
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
                              style:
                                  TextStyle(fontFamily: mainFont, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
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
