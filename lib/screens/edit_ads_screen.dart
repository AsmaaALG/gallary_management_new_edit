// screens/ads_management/edit_ads_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/classification.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:intl/intl.dart' as intl;

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

  String? _selectedClassification; // للتصنيف المختار
  List<Classification> _classifications = []; // قائمة التصنيفات
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _stopDate;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchClassifications();

    _loadAdData();
  }

  Future<void> _fetchClassifications() async {
    try {
      List<Map<String, dynamic>> classificationsData =
          await _firestoreService.getAllData('classification');
      setState(() {
        _classifications = classificationsData.map((data) {
          return Classification(
            id: data['documentId'], // تعيين المعرف
            name: data['name'], // تعيين الاسم
          );
        }).toList();
        print('التصنيفات: $_classifications');
      });
    } catch (e) {
      print('حدث خطأ أثناء جلب التصنيفات: $e');
    }
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

        var classificationRef =
            adData['classification id'] as DocumentReference?;
        _selectedClassification = classificationRef?.id; // تعيين المعرف مباشرة

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
        SnackBar(
            content: Text('حدث خطأ في تحميل بيانات الإعلان: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectStopDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _stopDate = picked;
      });
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
    setState(() => _isLoading = true);

    try {
      final classificationRef = FirebaseFirestore.instance
          .collection('classification')
          .doc(_selectedClassification); // استخدام المعرف مباشرة

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تعديل الإعلان',
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
        body: _isLoading && !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: const Text(
                            'يمكنك من خلال هذه الواجهة يمكنك تعديل بيانات الإعلان',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: mainFont,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // حقل اسم الإعلان
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'اسم الإعلان',
                            hintText: 'أدخل اسم الإعلان هنا',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم الإعلان';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _qrCodeController,
                          decoration: InputDecoration(
                            labelText: 'رمز QR',
                            hintText: 'أدخل رمز QR من هنا',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم الإعلان';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // حقل الموقع
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'الموقع',
                            hintText: 'أدخل موقع الإعلان هنا',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال موقع الإعلان';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // حقل رابط الصورة
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: 'رابط صورة الإعلان',
                            hintText: 'أدخل رابط الصورة هنا',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال رابط الصورة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Classification>(
                          value: _classifications.isNotEmpty
                              ? _classifications.firstWhere(
                                  (c) => c.id == _selectedClassification,
                                  orElse: () => _classifications[
                                      0], // إرجاع أول تصنيف إذا لم يتم العثور على تصنيف مطابق
                                )
                              : null,
                          decoration: InputDecoration(
                            labelText: 'التصنيف',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          items: _classifications.map((classification) {
                            return DropdownMenuItem<Classification>(
                              value: classification,
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(classification.name)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClassification =
                                  value?.id; // استخدم المعرف
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'يرجى اختيار التصنيف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // حقول التواريخ
                        _buildDateField('تاريخ البدء', _startDate,
                            () => _selectDate(context, true)),
                        const SizedBox(height: 16),
                        _buildDateField('تاريخ الانتهاء', _endDate,
                            () => _selectDate(context, false)),
                        const SizedBox(height: 16),
                        _buildDateField('تاريخ إيقاف الإعلان', _stopDate,
                            () => _selectStopDate(context)),
                        const SizedBox(height: 16),

                        // حقل الوصف
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'الوصف',
                            hintText: 'أدخل وصف الإعلان هنا',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال وصف الإعلان';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // زر التعديل
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            minimumSize: const Size(double.infinity, 50),
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 152, 150, 150)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? intl.DateFormat('dd-MM-yyyy').format(date)
                  : 'اختر التاريخ',
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
