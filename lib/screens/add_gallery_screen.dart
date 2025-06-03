import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/classification.dart';
import 'package:gallery_management/services/firestore_service.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _mapController = TextEditingController();

  Classification? _selectedClassification;
  List<Classification> _classifications = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClassifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _phoneController.dispose();
    _qrCodeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassifications() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('classification').get();

      setState(() {
        _classifications = querySnapshot.docs.map((doc) {
          return Classification(
            id: doc.id,
            name: doc['name'],
          );
        }).toList();
      });
    } catch (e) {
      print('حدث خطأ أثناء جلب التصنيفات: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب التصنيفات: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteClassification(String classificationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد أنك تريد حذف هذا التصنيف؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        // التحقق مما إذا كان التصنيف مرتبطًا بأي معارض
        final adsQuery = await FirebaseFirestore.instance
            .collection('2')
            .where('classification id',
                isEqualTo: FirebaseFirestore.instance
                    .collection('classification')
                    .doc(classificationId))
            .limit(1)
            .get();

        if (adsQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن حذف التصنيف لأنه مرتبط بمعارض'),
              backgroundColor: Colors.grey,
            ),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('classification')
            .doc(classificationId)
            .delete();

        setState(() {
          _classifications.removeWhere((c) => c.id == classificationId);
          if (_selectedClassification?.id == classificationId) {
            _selectedClassification = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التصنيف بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف التصنيف: ${e.toString()}')),
        );
      }
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
          .doc(_selectedClassification!.id);

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
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('classification')
            .add({'name': newClassification});

        await _fetchClassifications();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة التصنيف بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة التصنيف: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime initial = isStartDate ? now : (_startDate ?? now);

    final DateTime first =
        isStartDate ? DateTime(2000) : (_startDate ?? DateTime(2000));
    final DateTime last = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      if (!isStartDate && _startDate != null && picked.isBefore(_startDate!)) {
        // عرض رسالة خطأ إذا كان تاريخ الانتهاء قبل تاريخ البداية
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ الانتهاء يجب أن يكون بعد تاريخ البداية'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // مسح تاريخ الانتهاء إذا أصبح غير صالح
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
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
    final isWideScreen = MediaQuery.of(context).size.width > 600;

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
          padding: EdgeInsets.symmetric(
              vertical: 30.0, horizontal: isWideScreen ? 250 : 30),
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
                  _buildTextField(
                    controller: _titleController,
                    label: 'اسم المعرض',
                    hint: 'أدخل اسم المعرض هنا',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'الوصف',
                    hint: 'أدخل وصف المعرض هنا',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'الموقع',
                    hint: 'أدخل موقع المعرض هنا',
                  ),
                  const SizedBox(height: 16),
                  isWideScreen
                      ? Row(
                          children: [
                            Expanded(
                              flex: isWideScreen ? 3 : 2,
                              child: _buildTextField(
                                controller: _imageUrlController,
                                label: 'رابط صورة الغلاف',
                                hint:
                                    'قم برفع الصورة على imgur ثم نسخ رابط الصورة ووضعه هنا',
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                  onPressed: () async {
                                    if (await canLaunchUrl(imgurUrl)) {
                                      await launchUrl(imgurUrl,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      'افتح Imgur لرفع صورة',
                                      style: TextStyle(
                                          fontFamily: mainFont, fontSize: 10),
                                    ),
                                  )),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildTextField(
                              controller: _imageUrlController,
                              label: 'رابط صورة الغلاف',
                              hint:
                                  'قم برفع الصورة على imgur ثم نسخ رابط الصورة ووضعه هنا',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () async {
                                  if (await canLaunchUrl(imgurUrl)) {
                                    await launchUrl(imgurUrl,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      'افتح Imgur لرفع صورة',
                                      style: TextStyle(
                                          fontFamily: mainFont, fontSize: 10),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _mapController,
                    label: 'رابط صورة خارطة المعرض',
                    hint: 'أدخل رابط الصورة هنا',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _qrCodeController,
                    label: 'رمز QR',
                    hint: 'أدخل رمز QR هنا',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Classification>(
                          value: _selectedClassification,
                          isExpanded: true, // هذه السطر مهم لحل مشكلة العرض
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
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Row(
                                  children: [
                                    // أيقونة الحذف على اليسار
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => _deleteClassification(
                                          classification.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    // النص على اليمين
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          classification.name,
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addNewClassification,
                        child: const Text('+'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDateField('تاريخ البدء', _startDate,
                      () => _selectDate(context, true)),
                  const SizedBox(height: 20),
                  _buildDateField('تاريخ الانتهاء', _endDate,
                      () => _selectDate(context, false)),
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
                                color: Color.fromARGB(221, 255, 255, 255),
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
