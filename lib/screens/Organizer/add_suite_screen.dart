import 'package:gallery_management/pick_and_up_load_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

class AddSuiteScreen extends StatefulWidget {
  final String galleryId;

  const AddSuiteScreen({super.key, required this.galleryId});

  @override
  State<AddSuiteScreen> createState() => _AddSuiteScreenState();
}

class _AddSuiteScreenState extends State<AddSuiteScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _descCtl = TextEditingController();
  final TextEditingController _imageCtl = TextEditingController();
  final TextEditingController _titleCtl = TextEditingController();
  final TextEditingController _priceCtl = TextEditingController();
  final TextEditingController _sizeCtl = TextEditingController();
  final validMapTitleRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
  String? uploadedImageUrl;
  bool _isUploading = false;

  bool _isLoading = false;
  final Uri imgurUrl = Uri.parse('https://imgur.com/upload');

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _imageCtl.dispose();
    _titleCtl.dispose();
    _priceCtl.dispose();
    _sizeCtl.dispose();
    super.dispose();
  }

  Future<String?> _validateMapTitle(String? value, String galleryId) async {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى ملء هذا الحقل';
    }

    final title = value.trim();

    // تحقق من أن العنوان يحتوي فقط على أحرف إنجليزية وأرقام
    final validMapTitleRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!validMapTitleRegex.hasMatch(title)) {
      return 'العنوان يجب أن يحتوي على حروف إنجليزية وأرقام فقط';
    }

    // جلب الأجنحة التي تنتمي لنفس المعرض فقط
    final snapshot = await FirebaseFirestore.instance
        .collection('suite')
        .where('gallery id', isEqualTo: galleryId)
        .get();

    final lowerTitle = title.toLowerCase();

    // تحقق إذا كان العنوان موجود مسبقًا بدون حساسية لحالة الأحرف
    final exists = snapshot.docs.any((doc) {
      final existingTitle =
          (doc.data()['title on map'] ?? '').toString().toLowerCase();
      return existingTitle == lowerTitle;
    });

    if (exists) {
      return 'العنوان "$value" مستخدم بالفعل داخل هذا المعرض، يرجى اختيار عنوان آخر';
    }

    return null;
  }

  InputDecoration buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primaryColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtl.text.trim();

    if (title.isNotEmpty) {
      final titleError = await _validateMapTitle(title, widget.galleryId);
      if (titleError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(titleError)),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('suite').doc();

      final suiteData = {
        'gallery id': widget.galleryId,
        'name': _nameCtl.text.trim(),
        'description': _descCtl.text.trim(),
        'main image': _imageCtl.text.trim(),
        'title on map': _titleCtl.text.trim(),
        'price': _priceCtl.text.trim(),
        'size': _sizeCtl.text.trim()
      };

      // if (title.isNotEmpty) suiteData['title on map'] = title;
      // if (_priceCtl.text.trim().isNotEmpty) {
      //   suiteData['price'] = double.parse(_priceCtl.text.trim()) as String;
      // }
      // if (_sizeCtl.text.trim().isNotEmpty) {
      //   suiteData['size'] = double.parse(_sizeCtl.text.trim()) as String;
      // }

      await docRef.set(suiteData);

      if (mounted) {
        Navigator.pop(context, true); // نجاح الإضافة
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الإضافة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى ملء هذا الحقل';
    }
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final n = num.tryParse(value.trim());
    if (n == null) {
      return 'يرجى إدخال رقم صحيح';
    }
    if (n <= 0) {
      return 'يجب أن يكون الرقم أكبر من صفر';
    }
    return null;
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى ملء هذا الحقل';
    }
    final url = value.trim();
    final uri = Uri.tryParse(url);

    if (uri == null || (!uri.isAbsolute)) {
      return 'يرجى إدخال رابط صحيح';
    }

    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'يجب أن يبدأ الرابط بـ http أو https';
    }

    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    if (!imageExtensions.any((ext) => url.toLowerCase().endsWith(ext))) {
      return 'الرابط يجب أن يكون لصورة (jpg, png, gif...)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة جناح جديد',
            style: TextStyle(
                fontFamily: mainFont, fontSize: 16, color: Colors.white),
          ),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 30.0,
            horizontal: isWideScreen ? 250 : 30,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'يمكنك من خلال هذه الواجهة إضافة أجنحة جديدة للمعرض عبر تعبئة الحقول التالية',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameCtl,
                    decoration: buildInputDecoration(
                        'اسم الجناح', 'أدخل اسم الجناح هنا'),
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtl,
                    decoration: buildInputDecoration(
                        'وصف الجناح', 'أدخل وصف الجناح هنا'),
                    maxLines: 3,
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _imageCtl,
                  //   decoration: buildInputDecoration(
                  //       'رابط صورة الجناح', 'أدخل رابط الصورة هنا'),
                  //   validator: _validateImageUrl,
                  // ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUploading
                        ? null // لتعطيل الزر أثناء الرفع
                        : () async {
                            setState(() {
                              _isUploading = true;
                            });

                            final imageUrl = await pickAndUploadImage(
                              imgbbApiKey: '95daff58b10157f2de7ddd93301132e2',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'اختيار صورة الجناح',
                                style: TextStyle(
                                    fontFamily: mainFont, fontSize: 10),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtl,
                    decoration: buildInputDecoration(
                      'عنوان الجناح على الخارطة',
                      'يمكن تركه فارغًا',
                    ),
                    validator: (_) => null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sizeCtl,
                    decoration: buildInputDecoration(
                      'مساحة الجناح بالمتر المربع',
                      'يمكن تركها فارغة',
                    ),
                    validator: _validateNumber, // بدون تحقق
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceCtl,
                    decoration: buildInputDecoration(
                      'سعر الجناح بالدينار الليبي',
                      'يمكن تركه فارغًا',
                    ),
                    validator: _validateNumber, // بدون تحقق
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize:
                            Size(isWideScreen ? 250 : double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إضافة',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: mainFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
