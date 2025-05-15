import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/classification.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:intl/intl.dart' as intl;

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();

  Classification? _selectedClassification;
  List<Classification> _classifications = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClassifications(); // جلب التصنيفات عند بدء الشاشة
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _phoneController.dispose();
    _qrCodeController.dispose();
    super.dispose();
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

  Future<void> _addGallery() async {
    if (!_formKey.currentState!.validate()) return;

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
          .doc(_selectedClassification!.id); // استخدام المعرف

      DocumentSnapshot classificationDoc = await classificationRef.get();

      if (!classificationDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التصنيف غير صالح')),
        );
        return;
      }

      final galleryData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'phone': _phoneController.text,
        'classification id': classificationRef, // تخزين المرجع
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'qr code': _qrCodeController.text,
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

  Future<void> _addNewClassification() async {
    String? newClassification = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController newClassificationController =
            TextEditingController();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة تصنيف جديد'),
            content: TextField(
              controller: newClassificationController,
              decoration: const InputDecoration(hintText: 'أدخل اسم التصنيف'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(newClassificationController.text);
                },
                child: const Text('إضافة'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );

    if (newClassification != null && newClassification.isNotEmpty) {
      try {
        // إضافة التصنيف الجديد إلى Firestore
        await FirebaseFirestore.instance
            .collection('classification')
            .add({'name': newClassification});
        setState(() {
          _classifications.add(Classification(
              id: 'new_id', name: newClassification)); // استخدم معرفًا جديدًا
        });
        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة التصنيف بنجاح')),
        );
      } catch (e) {
        // إظهار رسالة فشل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة التصنيف: ${e.toString()}')),
        );
      }
    } else {
      // إظهار رسالة إذا كان التصنيف فارغًا
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم التصنيف')),
      );
    }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال $label';
        }
        return null;
      },
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
            borderSide: const BorderSide(color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة معرض جديد',
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'يمكنك من خلال هذه الواجهة إضافة معارض جديدة عبر تعبئة الحقول التالية',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: mainFont,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // حقل اسم المعرض
                  _buildTextField(
                    controller: _titleController,
                    label: 'اسم المعرض',
                    hint: 'أدخل اسم المعرض هنا',
                  ),
                  const SizedBox(height: 16),

                  // حقل الوصف
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'الوصف',
                    hint: 'أدخل وصف المعرض هنا',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // حقل الموقع
                  _buildTextField(
                    controller: _locationController,
                    label: 'الموقع',
                    hint: 'أدخل موقع المعرض هنا',
                  ),
                  const SizedBox(height: 16),

                  // حقل الهاتف
                  _buildTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    hint: 'أدخل رقم الهاتف هنا',
                  ),
                  const SizedBox(height: 16),

                  // حقل رابط الصورة
                  _buildTextField(
                    controller: _imageUrlController,
                    label: 'رابط الصورة',
                    hint: 'أدخل رابط الصورة هنا',
                  ),
                  const SizedBox(height: 16),

                  // حقل رمز QR
                  _buildTextField(
                    controller: _qrCodeController,
                    label: 'رمز QR',
                    hint: 'أدخل رمز QR هنا',
                  ),
                  const SizedBox(height: 16),
                  // قائمة التصنيفات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // استخدم Expanded لجعل القائمة تأخذ المساحة المتاحة
                        child: DropdownButtonFormField<Classification>(
                          value: _selectedClassification,
                          decoration: InputDecoration(
                            labelText: 'التصنيف',
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
                          items: _classifications
                              .map((Classification classification) {
                            return DropdownMenuItem<Classification>(
                              value: classification,
                              child: Align(
                                alignment: Alignment
                                    .centerRight, // محاذاة النص إلى اليمين
                                child: Text(classification.name),
                              ),
                            );
                          }).toList(),
                          onChanged: (Classification? newValue) {
                            setState(() {
                              _selectedClassification = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                          width: 10), // إضافة مسافة بين القائمة والزِر
                      ElevatedButton(
                        onPressed: _addNewClassification,
                        child: const Text('+'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // حقول التواريخ
                  _buildDateField('تاريخ البدء', _startDate,
                      () => _selectDate(context, true)),
                  const SizedBox(height: 20),
                  _buildDateField('تاريخ الانتهاء', _endDate,
                      () => _selectDate(context, false)),
                  const SizedBox(height: 20),
                  // زر الإضافة
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addGallery,
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
}
