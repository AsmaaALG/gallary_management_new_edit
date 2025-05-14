import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:intl/intl.dart' as intl;

class AddAdsScreen extends StatefulWidget {
  const AddAdsScreen({super.key});

  @override
  State<AddAdsScreen> createState() => _AddAdsScreenState();
}

class _AddAdsScreenState extends State<AddAdsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // متحكمات حقول النموذج
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _stopDate;
  bool _isLoading = false;

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

  Future<void> _addAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _stopDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد جميع التواريخ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text, // تغيير من category إلى imageUrl
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'stopAd': intl.DateFormat('dd-MM-yyyy').format(_stopDate!),
      };

      await _firestoreService.addData('ads', adData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الإعلان بنجاح')),
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
            'إضافة إعلان جديد',
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
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الجملة التوضيحية مع البادينج
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'يمكنك من خلال هذه الواجهة إضافة معارض الجديدة عبر تعبئة الحقول التالية',
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

                  // حقل رابط الصورة (بدلاً من الفئة)
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
                  const SizedBox(height: 20),

                  // حقول التواريخ
                  _buildDateField('تاريخ البدء', _startDate,
                      () => _selectDate(context, true)),
                  const SizedBox(height: 20),
                  _buildDateField('تاريخ الانتهاء', _endDate,
                      () => _selectDate(context, false)),
                  const SizedBox(height: 20),
                  _buildDateField('تاريخ إيقاف الإعلان', _stopDate,
                      () => _selectStopDate(context)),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 16),

                  // زر الإضافة
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 50),
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
                              color: Color.fromARGB(221, 255, 255, 255),
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
