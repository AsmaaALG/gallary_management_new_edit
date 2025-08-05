import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/pick_and_up_load_image.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/city_dropdown.dart';
import 'package:intl/intl.dart' as intl;
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/date_picker_widget.dart';
import 'package:gallery_management/widgets/classification_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AddAdsScreen2 extends StatefulWidget {
  final String companyId;
  const AddAdsScreen2({super.key, required this.companyId});

  @override
  State<AddAdsScreen2> createState() => _AddAdsScreenState();
}

class _AddAdsScreenState extends State<AddAdsScreen2> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _mapImageController = TextEditingController();

  String? _selectedClassification;
  String? _selectedCity;
  String? _companyName;
  String? uploadedImageUrl;
  bool _isUploading = false;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _stopDate;

  List<Map<String, dynamic>> _suites = [];
  List<Map<String, dynamic>> _partners = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _qrCodeController.dispose();
    _mapImageController.dispose();
    super.dispose();
  }

  Future<void> _showAddSuiteDialog() async {
    final nameCtl = TextEditingController();
    final areaCtl = TextEditingController();
    final priceCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة جناح', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: nameCtl,
                  textAlign: TextAlign.right,
                  maxLength: 5,
                  decoration: InputDecoration(
                    hintText: 'اسم الجناح',
                    counterText: '',
                    hintTextDirection: TextDirection.rtl,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: areaCtl,
                  textAlign: TextAlign.right,
                  maxLength: 5,
                  decoration: InputDecoration(
                    hintText: 'المساحة',
                    counterText: '',
                    hintTextDirection: TextDirection.rtl,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceCtl,
                  textAlign: TextAlign.right,
                  maxLength: 5,
                  decoration: InputDecoration(
                    hintText: 'السعر',
                    counterText: '',
                    hintTextDirection: TextDirection.rtl,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final name = nameCtl.text.trim();
                    final area = areaCtl.text.trim();
                    final price = priceCtl.text.trim();

                    if (name.length > 5 ||
                        area.length > 5 ||
                        price.length > 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('يجب ألا يتجاوز كل حقل 5 خانات')),
                      );
                      return;
                    }

                    final nameValid = RegExp(r'^[a-zA-Z0-9]+$');
                    if (!nameValid.hasMatch(name)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'الاسم يجب أن يحتوي على حروف إنجليزية وأرقام فقط')),
                      );
                      return;
                    }

                    final areaValid = RegExp(r'^[0-9\W_]+$');
                    if (!areaValid.hasMatch(area)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'المساحة يجب أن تحتوي على أرقام ورموز فقط')),
                      );
                      return;
                    }

                    final priceValid = RegExp(r'^[0-9\W_]+$');
                    if (!priceValid.hasMatch(price)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('السعر يجب أن يحتوي على أرقام فقط')),
                      );
                      return;
                    }

                    final nameLower = name.toLowerCase();
                    final alreadyExists = _suites.any((suite) =>
                        suite['name'].toString().toLowerCase() == nameLower);
                    if (alreadyExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('اسم الجناح مكرر')),
                      );
                      return;
                    }

                    setState(() {
                      _suites.add({
                        'name': name,
                        'area': area,
                        'price': price,
                        'status': 0,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCompanyName() async {
    try {
      final companySnapshot = await FirebaseFirestore.instance
          .collection('company')
          .doc(widget.companyId)
          .get();

      if (companySnapshot.exists) {
        setState(() {
          _companyName = companySnapshot['name'];
        });
      }
    } catch (e) {
      print('خطأ في جلب اسم الشركة: $e');
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

    if (!_isValidImageUrl(_imageUrlController.text) ||
        !_isValidImageUrl(_mapImageController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الصور')),
      );
      return;
    }

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

      final classificationDoc = await classificationRef.get();
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
        'map': _mapImageController.text,
        'classification id': classificationRef,
        'qr code': _qrCodeController.text,
        'start date': intl.DateFormat('dd-MM-yyyy').format(_startDate!),
        'end date': intl.DateFormat('dd-MM-yyyy').format(_endDate!),
        'stopAd': intl.DateFormat('dd-MM-yyyy').format(_stopDate!),
        'status': 'pending',
        'company_id': widget.companyId,
        'company_name': _companyName,
        'suites': _suites,
        'city': _selectedCity,
        'requested_by': FirebaseAuth.instance.currentUser!.uid,
        'requested_at': FieldValue.serverTimestamp(),
      };

      final adRef = await FirebaseFirestore.instance
          .collection('ads_requests')
          .add(adData);

      final adId = adRef.id;

// اضافة الشركاء
      for (var partner in _partners) {
        await FirebaseFirestore.instance.collection('partners').add({
          'name': partner['name'],
          'image': partner['image'],
          'ad_id': adId,
          'galleryId': null,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الإعلان بنجاح')),
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

  bool _isValidImageUrl(String url) {
    final RegExp regex =
        RegExp(r'^https?:\/\/.*\.(png|jpe?g|gif|bmp)', caseSensitive: false);
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
          title: const Text('إضافة إعلان جديد',
              style: TextStyle(
                  fontSize: 16, fontFamily: mainFont, color: Colors.white)),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: 20, horizontal: isWideScreen ? 50 : 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('قم بإضافة إعلان جديد عبر تعبئة الحقول التالية',
                        style: TextStyle(
                            fontSize: 14,
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                  ),
                  if (_companyName != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('اسم الشركة: $_companyName',
                          style: const TextStyle(
                              fontFamily: mainFont,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0))),
                    ),
                  const SizedBox(height: 16),
                  buildTextField(_titleController, 'اسم الإعلان',
                      'أدخل عنوان الاعلان', true),
                  const SizedBox(height: 16),
                  buildTextField(_descriptionController, 'الوصف',
                      'يرجى إدخال وصف المعرض', true,
                      maxLines: 3),
                  const SizedBox(height: 16),
                  buildTextField(
                      _qrCodeController, 'رمز QR', 'أدخل رمز ', false),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: buildTextField(
                          _locationController,
                          'الموقع',
                          'أدخل موقع المعرض هنا',
                          true,
                        ),
                      ),
                      const SizedBox(width: 7),
                      ElevatedButton(
                        onPressed: () async {
                          const imgurUrl = 'https://maps.google.com/';
                          await launchUrl(Uri.parse(imgurUrl));
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'google maps',
                            style: TextStyle(fontFamily: mainFont, fontSize: 8),
                          ),
                        ),
                      ),
                    ],
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
                              imgbbApiKey: '95daff58b10157f2de7ddd93301132e2',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                              imgbbApiKey: '95daff58b10157f2de7ddd93301132e2',
                            );

                            if (imageUrl != null) {
                              setState(() {
                                uploadedImageUrl = imageUrl;
                                _mapImageController.text = imageUrl;
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                  ClassificationDropdown(
                    selectedClassification: _selectedClassification,
                    onChanged: (value) =>
                        setState(() => _selectedClassification = value?.id),
                  ),
                  const SizedBox(height: 16),
                  CityDropdown(
                    selectedCity: _selectedCity,
                    onChanged: (value) =>
                        setState(() => _selectedCity = value?.id),
                  ),
                  const SizedBox(height: 16),
                  DatePickerField(
                    label: 'تاريخ البدء',
                    initialDate: _startDate,
                    endDateLimit: _endDate,
                    startDateLimit: DateTime.now(),
                    onDateChanged: (picked) {
                      setState(() {
                        _startDate = picked;
                        if (_endDate != null && _endDate!.isBefore(picked)) {
                          _endDate = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _startDate == null
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى تحديد تاريخ البداية أولاً'),
                                backgroundColor: Colors.grey,
                              ),
                            );
                          }
                        : null,
                    child: AbsorbPointer(
                      absorbing: _startDate == null,
                      child: DatePickerField(
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
                                backgroundColor: Colors.grey,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _endDate = picked;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: (_startDate == null || _endDate == null)
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'يرجى تحديد تاريخي البداية والنهاية أولاً'),
                                backgroundColor: Colors.grey,
                              ),
                            );
                          }
                        : null,
                    child: AbsorbPointer(
                      absorbing: _startDate == null || _endDate == null,
                      child: DatePickerField(
                        label: 'تاريخ إيقاف الإعلان',
                        initialDate: _stopDate,
                        startDateLimit: _startDate,
                        endDateLimit: _endDate,
                        onDateChanged: (picked) {
                          setState(() {
                            _stopDate = picked;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('الشركاء المضافين:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._partners.map((partner) => ListTile(
                        title: Text(partner['name']),
                        leading: partner['image'] != null
                            ? Image.network(partner['image'],
                                width: 40, height: 40)
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _partners.remove(partner)),
                        ),
                      )),
                  TextButton.icon(
                    onPressed: () async {
                      final newPartner = await showAddPartnerDialog();

                      if (newPartner != null) {
                        final exists = _partners.any((p) =>
                            p['name'].toString().toLowerCase() ==
                            newPartner['name']!.toLowerCase());

                        if (exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('اسم الشريك مكرر')),
                          );
                          return;
                        }

                        setState(() {
                          _partners.add(newPartner);
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة شريك'),
                  ),
                  const SizedBox(height: 16),
                  Text('الأجنحة المضافة:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._suites.map((suite) => ListTile(
                        title: Text(suite['name']),
                        subtitle: Text(
                            'المساحة: ${suite['area']} - السعر: ${suite['price']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _suites.remove(suite)),
                        ),
                      )),
                  TextButton.icon(
                    onPressed: _showAddSuiteDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة جناح'),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize:
                            Size(isWideScreen ? 250 : double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إضافة',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: mainFont,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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

  Future<Map<String, String>?> showAddPartnerDialog() async {
    final nameCtl = TextEditingController();
    String? partnerImageUrl;
    bool isUploading = false;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, localSetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة شريك', textAlign: TextAlign.right),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: nameCtl,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'اسم الشريك',
                      hintTextDirection: TextDirection.rtl,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            localSetState(() => isUploading = true);

                            final imageUrl = await pickAndUploadImage(
                              imgbbApiKey: '95daff58b10157f2de7ddd93301132e2',
                            );

                            if (imageUrl != null) {
                              localSetState(() => partnerImageUrl = imageUrl);
                            }

                            localSetState(() => isUploading = false);
                          },
                    child: Align(
                      alignment: Alignment.center,
                      child: isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(partnerImageUrl == null
                              ? 'اختر صورة الشريك'
                              : 'تم اختيار الصورة'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final name = nameCtl.text.trim();

                      if (name.isEmpty || partnerImageUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('يرجى إدخال جميع البيانات')),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        'name': name,
                        'image': partnerImageUrl!,
                      });
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
