import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/company_dropdown.dart';

class EditOrganizerScreen extends StatefulWidget {
  final String organizerId;

  const EditOrganizerScreen({Key? key, required this.organizerId})
      : super(key: key);

  @override
  State<EditOrganizerScreen> createState() => _EditOrganizerScreenState();
}

class _EditOrganizerScreenState extends State<EditOrganizerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  String? selectedCompanyId;
  bool isLoading = true;

  Future<void> _loadOrganizerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Organizer')
          .doc(widget.organizerId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        firstNameController.text = data['first name'] ?? '';
        lastNameController.text = data['last name'] ?? '';
        emailController.text = data['email'] ?? '';
        // passwordController.text = data['password'] ?? '';
        selectedCompanyId = data['company_id'];
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("فشل في تحميل بيانات المنظم: $e");
    }
  }

  Future<void> _updateOrganizer() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('Organizer')
            .doc(widget.organizerId)
            .update({
          'first name': firstNameController.text.trim(),
          'last name': lastNameController.text.trim(),
          // 'password': passwordController.text.trim(),
          'company_id': selectedCompanyId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات المنظم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrganizerData();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل بيانات المنظم',
              style: TextStyle(
                  fontFamily: mainFont, color: Colors.white, fontSize: 16)),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 30, horizontal: isWideScreen ? 250 : 30),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'يمكنك تعديل بيانات المنظم أدناه',
                          style: TextStyle(
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 30),
                        buildTextField(firstNameController, 'الاسم الأول',
                            'أدخل الاسم الأول', true),
                        const SizedBox(height: 16),
                        buildTextField(lastNameController, 'الاسم الأخير',
                            'أدخل الاسم الأخير', true),
                        const SizedBox(height: 16),
                        buildTextField(
                          emailController,
                          'البريد الإلكتروني',
                          '',
                          false,
                          readOnly: true,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        // buildTextField(
                        //   passwordController,
                        //   'كلمة المرور',
                        //   'أدخل كلمة المرور',
                        //   true,
                        //   isPassword: true,
                        //   obscureText: obscurePassword,
                        //   toggleObscure: () {
                        //     setState(() {
                        //       obscurePassword = !obscurePassword;
                        //     });
                        //   },
                        //   validator: (value) {
                        //     if (value == null || value.trim().isEmpty) {
                        //       return 'الرجاء إدخال كلمة المرور';
                        //     } else if (value.trim().length < 6) {
                        //       return 'كلمة المرور يجب ألا تقل عن 6 خانات';
                        //     }
                        //     return null;
                        //   },
                        // ),
                        // const SizedBox(height: 16),
                        // CompanyDropdown(
                        //   selectedCompanyId: selectedCompanyId,
                        //   onChanged: (value) {
                        //     selectedCompanyId = value;
                        //   },
                        // ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: _updateOrganizer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize: Size(
                                  isWideScreen ? 250 : double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: mainFont,
                                  fontSize: 16),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
