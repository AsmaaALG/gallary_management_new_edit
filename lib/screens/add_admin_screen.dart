import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/user_session.dart';
import 'package:gallery_management/services/firestore_service.dart';

class AddAdminScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const AddAdminScreen({Key? key, required this.firestoreService})
      : super(key: key);

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  int selectedState = 0;

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة مسؤول جديد',
            style: TextStyle(
              fontSize: 16,
              fontFamily: mainFont,
              color: Colors.white,
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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'يمكنك من خلال هذه الواجهة إضافة مسؤول جديد عبر تعبئة الحقول التالية',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(firstNameController, 'الاسم الأول',
                      'أدخل الاسم الأول هنا', validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم الأول';
                    }
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(lastNameController, 'الاسم الأخير',
                      'أدخل الاسم الأخير هنا', validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم الأخير';
                    }
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, 'البريد الإلكتروني',
                      'أدخل البريد الإلكتروني هنا', validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'صيغة البريد الإلكتروني غير صحيحة';
                    }
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(
                      passwordController, 'كلمة المرور', 'أدخل كلمة المرور هنا',
                      validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.trim().length < 6) {
                      return 'كلمة المرور يجب ألا تقل عن 6 خانات';
                    }
                    return null;
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    'الصلاحيات',
                    style: TextStyle(
                        fontFamily: mainFont, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedState,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('صلاحيات كاملة')),
                      ),
                      DropdownMenuItem(
                        value: 0,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('صلاحيات محدودة')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedState = value ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            final success =
                                await widget.firestoreService.createUser(
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              state: selectedState,
                            );

                            if (success) {
                              Navigator.pop(context);
                              if (UserSession.email != null &&
                                  UserSession.password != null) {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                  email: UserSession.email!,
                                  password: UserSession.password!,
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تمت إضافة المسؤول بنجاح'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('البريد الإلكتروني مستخدم مسبقًا'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ أثناء الإضافة: $e'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize:
                            Size(isWideScreen ? 250 : double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'إضافة',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: mainFont,
                          color: Colors.white,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
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
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
    );
  }
}
