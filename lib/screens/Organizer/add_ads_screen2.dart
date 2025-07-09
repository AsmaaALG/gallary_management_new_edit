import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/city_dropdown.dart';
import 'package:intl/intl.dart' as intl;
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AddAdsScreen2 extends StatefulWidget {
  final String companyId;
  const AddAdsScreen2({super.key, required this.companyId});

  @override
  State<AddAdsScreen2> createState() => _AddAdsScreenState();
}

class _AddAdsScreenState extends State<AddAdsScreen2> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _mapImageController = TextEditingController();

  String? _selectedClassification;
  String? _selectedCity;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _stopDate;

  List<Map<String, dynamic>> _suites = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  Future<void> _showAddSuiteDialog() async {
    final nameCtl = TextEditingController();
    final areaCtl = TextEditingController();
    final priceCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة جناح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtl,
                decoration: InputDecoration(hintText: 'اسم الجناح')),
            TextField(
                controller: areaCtl,
                decoration: InputDecoration(hintText: 'المساحة')),
            TextField(
                controller: priceCtl,
                decoration: InputDecoration(hintText: 'السعر')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (nameCtl.text.trim().isEmpty ||
                  areaCtl.text.trim().isEmpty ||
                  priceCtl.text.trim().isEmpty) return;
              setState(() {
                _suites.add({
                  'name': nameCtl.text.trim(),
                  'area': areaCtl.text.trim(),
                  'price': priceCtl.text.trim(),
                });
              });
              Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAd() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null || _stopDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد جميع التواريخ')),
      );
      return;
    }

    if (_selectedClassification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تصنيف')),
      );
      return;
    }

    if (!_isValidImageUrl(_imageUrlController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رابط صورة صحيح')),
      );
      return;
    }

    if (!_isValidMapUrl(_locationController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رابط موقع Google Maps صالح')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final classificationRef = FirebaseFirestore.instance
          .collection('classification')
          .doc(_selectedClassification);

      final classificationDoc = await classificationRef.get();
      if (!classificationDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التصنيف غير صالح')),
        );
        return;
      }

      final adData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'map': _mapImageController.text,
        'classification id': classificationRef,
        'qr code': _qrCodeController.text,
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'stopAd': intl.DateFormat('dd-MM-yyyy').format(_stopDate!),
        'status': 'pending',
        'company_id': widget.companyId,
        'suites': _suites,
        'city': _selectedCity,
        'requested_by': FirebaseAuth.instance.currentUser!.uid,
        'requested_at': FieldValue.serverTimestamp(),
      };

      await _firestoreService.addData('ads_requests', adData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الإعلان بنجاح')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// دالة التحقق من رابط الصورة
  bool _isValidImageUrl(String url) {
    final RegExp regex = RegExp(r'^(https?:\/\/.*\.(?:png|jpg|jpeg|gif|bmp))$',
        caseSensitive: false);
    return regex.hasMatch(url);
  }

// دالة التحقق من رابط Google Maps
  bool _isValidMapUrl(String url) {
    final cleanedUrl = url.trim();
    final RegExp regex = RegExp(
      r'^(https?:\/\/)?(www\.google\.com\/maps|goo\.gl\/maps|maps\.app\.goo\.gl)\/.+',
      caseSensitive: false,
    );
    return regex.hasMatch(cleanedUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة إعلان جديد',
              style: TextStyle(
                  fontSize: 16, fontFamily: mainFont, color: Colors.white)),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: 30, horizontal: isWideScreen ? 250 : 30),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('قم بإضافة إعلان جديد عبر تعبئة الحقول التالية',
                        style: TextStyle(
                            fontSize: 14,
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                  ),
                  const SizedBox(height: 30),
                  buildTextField(_titleController, 'اسم الإعلان',
                      'أدخل عنوان الاعلان', true),
                  const SizedBox(height: 16),
                  buildTextField(
                      _qrCodeController, 'رمز QR', 'أدخل رمز ', false),
                  const SizedBox(height: 16),
                  buildTextField(_locationController, 'الموقع',
                      'أدخل موقع المعرض هنا', true),
                  const SizedBox(height: 16),
                  buildTextField(_imageUrlController, 'رابط صورة الإعلان',
                      'أدخل رابط الصورة هنا', true),
                  const SizedBox(height: 16),
                  buildTextField(_mapImageController, 'رابط صورة خارطة المعرض',
                      'أدخل رابط الصورة هنا', true),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      if (await canLaunchUrl(imgurUrl)) {
                        await launchUrl(imgurUrl,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('افتح Imgur لرفع صورة'),
                  ),
                  const SizedBox(height: 16),
                  ClassificationDropdown(
                    selectedClassification: _selectedClassification,
                    onChanged: (value) =>
                        setState(() => _selectedClassification = value?.id),
                  ),
                  const SizedBox(height: 16),
                  CityDropdown(
                    selectedCity: _selectedCity,
                    onChanged: (value) =>
                        setState(() => _selectedCity = value?.id),
                  ),

                  const SizedBox(height: 16),
                  DatePickerField(
                      label: 'تاريخ البدء',
                      initialDate: _startDate,
                      endDateLimit: _endDate,
                      onDateChanged: (picked) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate != null && _endDate!.isBefore(picked)) {
                            _endDate = null;
                          }
                        });
                      }),
                  const SizedBox(height: 16),
                  DatePickerField(
                    label: 'تاريخ الانتهاء',
                    initialDate: _endDate,
                    startDateLimit: _startDate,
                    onDateChanged: (picked) {
                      if (_startDate != null && picked.isBefore(_startDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تاريخ الانتهاء يجب أن يكون بعد تاريخ البداية'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _endDate = picked;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DatePickerField(
                      label: 'تاريخ إيقاف الإعلان',
                      initialDate: _stopDate,
                      onDateChanged: (picked) =>
                          setState(() => _stopDate = picked)),
                  const SizedBox(height: 16),
                  buildTextField(
                      _descriptionController, 'الوصف', 'أدخل الوصف هنا', true,
                      maxLines: 3),
                  const SizedBox(height: 16),

                  // عرض الأجنحة المضافة
                  Text('الأجنحة المضافة:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._suites.map((suite) => ListTile(
                        title: Text(suite['name']),
                        subtitle: Text(
                            'المساحة: ${suite['area']} - السعر: ${suite['price']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _suites.remove(suite)),
                        ),
                      )),
                  TextButton.icon(
                    onPressed: _showAddSuiteDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة جناح'),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize:
                            Size(isWideScreen ? 100 : double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إضافة',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: mainFont,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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
