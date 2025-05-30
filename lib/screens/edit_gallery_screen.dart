import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/classification.dart';
import 'package:gallery_management/services/firestore_service.dart';
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

  String? _selectedClassification; // للتصنيف المختار
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isInitialized = false;

  List<Classification> _classifications = []; // قائمة التصنيفات

  @override
  void initState() {
    super.initState();
    _fetchClassifications(); // جلب التصنيفات عند بدء الشاشة
    _fetchGalleryData(); // جلب بيانات المعرض
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

        var classificationRef = data['classification id'] as DocumentReference?;
        _selectedClassification = classificationRef?.id; // تعيين المعرف مباشرة

        final dateFormat = intl.DateFormat('dd-MM-yyyy');
        _startDate = data['start date'] != null
            ? dateFormat.parse(data['start date'])
            : null;
        _endDate = data['end date'] != null
            ? dateFormat.parse(data['end date'])
            : null;
      });
    } else {
      // معالجة الحالة عندما لا توجد بيانات
      setState(() {
        _isLoading = false;
        _isInitialized = true; // تعيين الحالة بعد التحميل
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
        'map': _mapController.text,
        'classification id': classificationRef, // تخزين المرجع
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
        body: _isLoading && !_isInitialized
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
                        const SizedBox(height: 30),
                        _buildTextField(_titleController, 'اسم المعرض',
                            'يرجى إدخال اسم المعرض'),
                        const SizedBox(height: 16),
                        _buildTextField(
                            _locationController, 'الموقع', 'يرجى إدخال الموقع'),
                        const SizedBox(height: 16),
                        _buildTextField(_imageUrlController,
                            'رابط صورة غلاف المعرض', 'يرجى إدخال رابط الصورة'),
                        const SizedBox(height: 16),
                        _buildTextField(_mapController,
                            'رابط صورة خارطة المعرض', 'يرجى إدخال رابط الصورة'),

                        const SizedBox(height: 16),
                        _buildDateField('تاريخ البدء', _startDate,
                            () => _selectDate(context, true)),
                        const SizedBox(height: 16),
                        _buildDateField('تاريخ الانتهاء', _endDate,
                            () => _selectDate(context, false)),
                        const SizedBox(height: 16),

                        // حقل اختيار التصنيف
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

                        _buildTextField(_descriptionController, 'الوصف',
                            'يرجى إدخال وصف المعرض',
                            maxLines: 3),
                        const SizedBox(height: 30),
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

  Widget _buildTextField(
      TextEditingController controller, String label, String errorMessage,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorMessage;
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
