import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/city_dropdown.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

class RequestAddGalleryScreen extends StatefulWidget {
  final String companyId;
  const RequestAddGalleryScreen({super.key, required this.companyId});

  @override
  State<RequestAddGalleryScreen> createState() =>
      _RequestAddGalleryScreenState();
}

class _RequestAddGalleryScreenState extends State<RequestAddGalleryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _mapController = TextEditingController();

  String? _selectedClassification;
  String? _selectedCity;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _companyName;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
  }

  Future<void> _fetchCompanyName() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final organizerSnapshot = await FirebaseFirestore.instance
          .collection('Organizer')
          .doc(userId)
          .get();

      if (organizerSnapshot.exists) {
        final companyId = organizerSnapshot['company_id'];

        final companySnapshot = await FirebaseFirestore.instance
            .collection('company')
            .doc(companyId)
            .get();

        if (companySnapshot.exists) {
          setState(() {
            _companyName = companySnapshot['name'];
          });
        }
      }
    } catch (e) {
      print('خطأ في جلب اسم الشركة: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassification == null ||
        _startDate == null ||
        _endDate == null ||
        _companyName == null ||
        _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة كل الحقول المطلوبة')),
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

      final requestData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'map': _mapController.text,
        'QR code': _qrCodeController.text,
        'classification id': classificationRef,
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'company_id': widget.companyId,
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'company_name': _companyName,
        'status': 'pending',
        'city': _selectedCity,
        'requested_by': FirebaseAuth.instance.currentUser!.uid,
        'requested_at': FieldValue.serverTimestamp(),
      };

      await _firestoreService.addData('gallery_requests', requestData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب المعرض بنجاح')),
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _qrCodeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب إضافة معرض',
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
              vertical: 20.0,
              horizontal: isWideScreen ? 30 : 10), // تقليل البادينق
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_companyName != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('اسم الشركة: $_companyName',
                          style: const TextStyle(
                              fontFamily: mainFont,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                    ),
                  const SizedBox(height: 30),
                  buildTextField(
                      _titleController, 'اسم المعرض', 'أدخل اسم المعرض', true),
                  const SizedBox(height: 16),
                  buildTextField(
                      _qrCodeController, 'رمز QR', 'أدخل رمز', false),
                  const SizedBox(height: 16),
                  buildTextField(
                      _locationController, 'الموقع', 'أدخل موقع المعرض', true),
                  const SizedBox(height: 16),
                  buildTextField(_imageUrlController, 'رابط صورة الغلاف',
                      'رابط مباشر للصورة', true),
                  const SizedBox(height: 16),
                  buildTextField(_mapController, 'رابط خارطة المعرض',
                      'رابط صورة لخارطة المعرض', false),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final Uri imgurUrl =
                          Uri.parse('https://imgur.com/upload');
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
                  buildTextField(_descriptionController, 'الوصف',
                      'أدخل وصفًا للمعرض', true,
                      maxLines: 3),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize:
                            Size(isWideScreen ? 100 : double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إرسال الطلب',
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
