import 'package:flutter/material.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:intl/intl.dart' as intl;
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/services/firestore_service.dart';


class EditAdsScreen extends StatefulWidget {
  final String adId;
  const EditAdsScreen({super.key, required this.adId});

  @override
  State<EditAdsScreen> createState() => _EditAdsScreenState();
}

class _EditAdsScreenState extends State<EditAdsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();

  String? _selectedClassification;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _stopDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdData();
  }

  Future<void> _loadAdData() async {
    setState(() => _isLoading = true);
    try {
      final adData = await _firestoreService.getAdById(widget.adId);
      if (adData != null) {
        _titleController.text = adData['title'] ?? '';
        _descriptionController.text = adData['description'] ?? '';
        _locationController.text = adData['location'] ?? '';
        _imageUrlController.text = adData['image url'] ?? '';
        _qrCodeController.text = adData['QR code'] ?? '';
        _selectedClassification =
            (adData['classification id'] as DocumentReference?)?.id;
        final dateFormat = intl.DateFormat('dd-MM-yyyy');
        _startDate = adData['start date'] != null
            ? dateFormat.parse(adData['start date'])
            : null;
        _endDate = adData['end date'] != null
            ? dateFormat.parse(adData['end date'])
            : null;
        _stopDate = adData['stopAd'] != null
            ? dateFormat.parse(adData['stopAd'])
            : null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل البيانات: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAd() async {
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

    setState(() => _isLoading = true);

    try {
      final classificationRef = FirebaseFirestore.instance
          .collection('classification')
          .doc(_selectedClassification);

      final updatedData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'QR code': _qrCodeController.text,
        'classification id': classificationRef,
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'stopAd': intl.DateFormat('dd-MM-yyyy').format(_stopDate!),
      };

      await _firestoreService.updateAd(widget.adId, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الإعلان بنجاح')),
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

  bool _isValidImageUrl(String url) {
    final RegExp regex = RegExp(
      r'^(https?:\/\/.*\.(?:png|jpg|jpeg|gif|bmp))$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الإعلان',
              style: TextStyle(
                  fontSize: 16, fontFamily: mainFont, color: Colors.white)),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 30, horizontal: isWideScreen ? 250 : 30),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'يمكنك من خلال هذه الواجهة تعديل بيانات الإعلان',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 30),
                        buildTextField(_titleController, 'اسم الإعلان',
                            'يرجى إدخال اسم الإعلان', true),
                        const SizedBox(height: 16),
                        buildTextField(_qrCodeController, 'رمز QR',
                            'يرجى إدخال رمز QR', false),
                        const SizedBox(height: 16),
                        buildTextField(_locationController, 'الموقع',
                            'يرجى إدخال الموقع', true),
                        const SizedBox(height: 16),
                        buildTextField(_imageUrlController, 'رابط الصورة',
                            'يرجى إدخال رابط الصورة', true),
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
                          onDateChanged: (picked) {
                            setState(() {
                              _startDate = picked;
                              if (_endDate != null &&
                                  _endDate!.isBefore(picked)) {
                                _endDate = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DatePickerField(
                          label: 'تاريخ الانتهاء',
                          initialDate: _endDate,
                          startDateLimit: _startDate,
                          onDateChanged: (picked) {
                            if (_startDate != null &&
                                picked.isBefore(_startDate!)) {
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
                          onDateChanged: (picked) {
                            setState(() {
                              _stopDate = picked;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        buildTextField(_descriptionController, 'الوصف',
                            'يرجى إدخال وصف الإعلان', true,
                            maxLines: 3),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateAd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize:
                                  Size(isWideScreen ? 250 : double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'حفظ التعديلات',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: mainFont,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
