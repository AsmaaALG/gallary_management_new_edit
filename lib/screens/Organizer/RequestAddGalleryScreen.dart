import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

class RequestAddGalleryScreen extends StatefulWidget {
  const RequestAddGalleryScreen({super.key});

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
  final TextEditingController _suitesCountController = TextEditingController();

  String? _selectedClassification;
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
        _companyName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة كل الحقول المطلوبة')),
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
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'company_name': _companyName,
        'status': 'pending', // للحالة المستقبلية للقبول أو الرفض
        'requested_by': FirebaseAuth.instance.currentUser!.uid,
        'requested_at': FieldValue.serverTimestamp(),
      };

      await _firestoreService.addData('gallery_requests', requestData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب بنجاح')),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _qrCodeController.dispose();
    _mapController.dispose();
    _suitesCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          title: const Text(
            'طلب إضافة معرض',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: 30.0, horizontal: isWideScreen ? 250 : 30),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_companyName != null)
                    Text('اسم الشركة: $_companyName',
                        style: const TextStyle(
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                  const SizedBox(height: 30),
                  buildTextField(
                      _titleController, 'اسم المعرض', 'أدخل اسم المعرض', true),
                  const SizedBox(height: 20),
                  buildTextField(_descriptionController, 'الوصف',
                      'أدخل وصفًا للمعرض', true,
                      maxLines: 3),
                  const SizedBox(height: 20),
                  buildTextField(
                      _locationController, 'الموقع', 'أدخل موقع المعرض', true),
                  const SizedBox(height: 17),
                  buildTextField(_imageUrlController, 'رابط صورة الغلاف',
                      'رابط مباشر للصورة', true),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
                  buildTextField(_mapController, 'رابط خارطة المعرض',
                      'رابط صورة لخارطة المعرض', false),
                  const SizedBox(height: 20),
                  buildTextField(
                      _qrCodeController, 'رمز QR', 'رمز QR إن وجد', false),
                  const SizedBox(height: 20),
                  ClassificationDropdown(
                    selectedClassification: _selectedClassification,
                    onChanged: (value) {
                      setState(() {
                        _selectedClassification = value?.id;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DatePickerField(
                    label: 'تاريخ البدء',
                    initialDate: _startDate,
                    endDateLimit: _endDate,
                    onDateChanged: (picked) =>
                        setState(() => _startDate = picked),
                  ),
                  const SizedBox(height: 20),
                  DatePickerField(
                    label: 'تاريخ الانتهاء',
                    initialDate: _endDate,
                    startDateLimit: _startDate,
                    onDateChanged: (picked) =>
                        setState(() => _endDate = picked),
                  ),
                  const SizedBox(height: 20),
                  // buildTextField(
                  //   _suitesCountController,
                  //   'عدد الأجنحة',
                  //   'عدد الأجنحة المتوفرة',
                  //   true,
                  //   keyboardType: TextInputType.number,
                  // ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
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
                            'إرسال الطلب',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: mainFont,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
