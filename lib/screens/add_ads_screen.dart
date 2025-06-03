import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:gallery_management/models/classification.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController _qrCodeController = TextEditingController();

  Classification? _selectedClassification;
  List<Classification> _classifications = [];
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

  @override
  void initState() {
    super.initState();
    _fetchClassifications(); // جلب التصنيفات عند بدء الشاشة
  }

///////////////////////////////////////////تصنيـــــــات
  ///
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

  Future<void> _selectStopDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = _endDate ?? now;

    final DateTime first = DateTime(2000);
    final DateTime last = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
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
    if (_selectedClassification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تصنيف')),
      );
      return;
    }

    // تحقق من رابط الصورة
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
          .doc(_selectedClassification!.id); // استخدام المعرف

      DocumentSnapshot classificationDoc = await classificationRef.get();

      if (!classificationDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التصنيف غير صالح')),
        );
        return;
      }
      final adData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'image url': _imageUrlController.text,
        'classification id': classificationRef, // تخزين المرجع
        'qr code': _qrCodeController.text,
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

// دالة للتحقق من رابط الصورة
  bool _isValidImageUrl(String url) {
    final RegExp regex = RegExp(
      r'^(https?:\/\/.*\.(?:png|jpg|jpeg|gif|bmp))$', // تحقق من امتدادات الصور
      caseSensitive: false,
    );
    return regex.hasMatch(url);
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
            title: const Text(
              'إضافة تصنيف جديد',
              style: TextStyle(
                  fontFamily: mainFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
            content: TextField(
              controller: newClassificationController,
              decoration: const InputDecoration(hintText: 'أدخل اسم التصنيف'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(newClassificationController.text);
                },
                child: const Text(
                  'إضافة',
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 11,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 11,
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

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
          padding: EdgeInsets.symmetric(
              vertical: 30, horizontal: isWideScreen ? 250 : 30),
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
                  TextFormField(
                    controller: _qrCodeController,
                    decoration: InputDecoration(
                      labelText: 'رمز QR',
                      hintText: 'أدخل رمز QR هنا',
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

                  // حقل رابط الصورة
                  isWideScreen
                      ? Row(
                          children: [
                            Expanded(
                              flex: isWideScreen ? 3 : 2,
                              child: TextFormField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  labelText: 'رابط صورة الإعلان',
                                  hintText:
                                      'قم برفع الصورة على imgur ثم نسخ رابط الصورة ووضعه هنا',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(40),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
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
                            TextFormField(
                              controller: _imageUrlController,
                              style: TextStyle(fontSize: 10),
                              decoration: InputDecoration(
                                labelText: 'رابط صورة الإعلان',
                                hintText:
                                    'قم برفع الصورة على imgur ثم نسخ رابط الصورة ووضعه هنا',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
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
                  // قائمة التصنيفات
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

                  const SizedBox(height: 20),
                  // زر الإضافة
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addAd,
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
