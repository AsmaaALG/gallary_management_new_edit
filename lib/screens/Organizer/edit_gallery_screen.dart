import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/pick_and_up_load_image.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:gallery_management/widgets/city_dropdown.dart';
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:intl/intl.dart' as intl;

class EditGalleryScreen extends StatefulWidget {
  final String galleryId;
  const EditGalleryScreen({super.key, required this.galleryId});

  @override
  State<EditGalleryScreen> createState() => _EditGalleryScreenState();
}

class _EditGalleryScreenState extends State<EditGalleryScreen> {
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
  bool _isLoading = false;
  bool _isInitialized = false;
  String? uploadedImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchGalleryData();
  }

  Future<void> _fetchGalleryData() async {
    var data = await _firestoreService.getDocumentById('2', widget.galleryId);

    if (data != null) {
      setState(() {
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _locationController.text = data['location'] ?? '';
        _imageUrlController.text = data['image url'] ?? '';
        _qrCodeController.text = data['QR code'] ?? '';
        _mapController.text = data['map'] ?? '';
        _selectedCity = data['city'] ?? '';

        var classificationRef = data['classification id'] as DocumentReference?;
        _selectedClassification = classificationRef?.id;

        final dateFormat = intl.DateFormat('dd-MM-yyyy');
        _startDate = data['start date'] != null
            ? dateFormat.parse(data['start date'])
            : null;
        _endDate = data['end date'] != null
            ? dateFormat.parse(data['end date'])
            : null;
        _isInitialized = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }

  Future<void> _updateGallery() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
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
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المدينة')),
      );
      return;
    }

    // if (!_isValidImageUrl(_imageUrlController.text) ||
    //     !_isValidImageUrl(_mapController.text)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('يرجى إدخال رابط صورة صحيح')),
    //   );
    //   return;
    // }
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

      DocumentSnapshot classificationDoc = await classificationRef.get();

      if (!classificationDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التصنيف غير صالح')),
        );
        return;
      }

      final updatedData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'QR code': _qrCodeController.text,
        'map': _mapController.text,
        'classification id': classificationRef,
        'city': _selectedCity,
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
      };

      await _firestoreService.updateGallery(widget.galleryId, updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
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
          title: const Text(
            'تعديل على المعرض',
            style: TextStyle(
              fontSize: 16,
              fontFamily: mainFont,
              color: Color.fromARGB(221, 255, 255, 255),
            ),
          ),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: isWideScreen ? 50 : 20), // تقليل البادينق
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: const Text(
                            'يمكنك من خلال هذه الواجهة تعديل بيانات المعرض',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: mainFont,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // تقليل الفاصل
                        buildTextField(_titleController, 'اسم المعرض',
                            'يرجى إدخال اسم المعرض', true),
                        const SizedBox(height: 16),
                        buildTextField(_locationController, 'الموقع',
                            'يرجى إدخال الموقع', true),
                        const SizedBox(height: 16),
                        buildTextField(_qrCodeController, 'رمز الQR',
                            'يرجى إدخال رمز QR', false),
                        const SizedBox(height: 16),
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
                                      _imageUrlController.text = imageUrl;
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
                                      'اختر صورة الغلاف',
                                      style: TextStyle(
                                          fontFamily: mainFont, fontSize: 10),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
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
                                      _mapController.text = imageUrl;
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
                                      'اختر صورةالخارطة',
                                      style: TextStyle(
                                          fontFamily: mainFont, fontSize: 10),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // buildTextField(_mapController, 'رابط صورة خارطة المعرض',
                        //     'يرجى إدخال رابط الصورة', false),
                        // const SizedBox(height: 16),
                        // City Dropdown
                        CityDropdown(
                          selectedCity: _selectedCity,
                          onChanged: (value) => setState(() {
                            _selectedCity = value?.id;
                          }),
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
                        buildTextField(_descriptionController, 'الوصف',
                            'يرجى إدخال وصف المعرض', true,
                            maxLines: 3),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateGallery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize: Size(
                                  isWideScreen ? 100 : double.infinity, 50),
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
                                      color: Color.fromARGB(221, 255, 255, 255),
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
