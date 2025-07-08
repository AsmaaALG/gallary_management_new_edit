import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

class AddGalleryScreen extends StatefulWidget {
  const AddGalleryScreen({super.key});

  @override
  State<AddGalleryScreen> createState() => _AddGalleryScreenState();
}

class _AddGalleryScreenState extends State<AddGalleryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _mapController = TextEditingController();

  String? _selectedClassification;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

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

  Future<void> _addGallery() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تصنيف')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ البدء والانتهاء')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final classificationRef = FirebaseFirestore.instance
          .collection('classification')
          .doc(_selectedClassification);

      final galleryData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'map': _mapController.text,
        'classification id': classificationRef,
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'QR code': _qrCodeController.text,
      };

      await _firestoreService.addData('2', galleryData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المعرض بنجاح')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة معرض جديد',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white),
          ),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: 30.0, horizontal: isWideScreen ? 250 : 30),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'يمكنك من خلال هذه الواجهة إضافة معارض جديدة عبر تعبئة الحقول التالية',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  buildTextField(
                     _titleController,
                     'اسم المعرض',
                   'أدخل اسم المعرض هنا',
                     true,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    _descriptionController,
                     'الوصف',
                    'أدخل وصف المعرض هنا',
                     true,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                     _locationController,
                    'الموقع',
                    'أدخل موقع المعرض هنا',
                     true,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    _imageUrlController,
                   'رابط صورة الغلاف',
                     'أدخل رابط الصورة من Imgur',
                     true,
                  ),
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
                  const SizedBox(height: 16),
                  buildTextField(
                 _mapController,
                    'رابط خارطة المعرض',
                     'رابط صورة للخارطة (اختياري)',
                    false,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    _qrCodeController,
                     'رمز QR',
                    'رمز QR إن وجد',
                     false,
                  ),
                  const SizedBox(height: 16),
                  ClassificationDropdown(
                    selectedClassification: _selectedClassification,
                    onChanged: (value) {
                      setState(() {
                        _selectedClassification = value?.id;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DatePickerField(
                    label: 'تاريخ البدء',
                    initialDate: _startDate,
                    endDateLimit: _endDate,
                    onDateChanged: (pickedDate) {
                      setState(() {
                        _startDate = pickedDate;
                        if (_endDate != null &&
                            _endDate!.isBefore(_startDate!)) {
                          _endDate = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DatePickerField(
                    label: 'تاريخ الانتهاء',
                    initialDate: _endDate,
                    startDateLimit: _startDate,
                    onDateChanged: (pickedDate) {
                      setState(() {
                        _endDate = pickedDate;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addGallery,
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