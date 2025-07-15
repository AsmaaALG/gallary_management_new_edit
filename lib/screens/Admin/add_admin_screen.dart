import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/user_session.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';

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

  bool isValidEmail(String email) {
    final RegExp regex = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$",
      caseSensitive: false,
    );

    final allowedDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'icloud.com',
    ];

    if (!regex.hasMatch(email)) return false;

    final domain = email.split('@').last.toLowerCase();
    return allowedDomains.contains(domain);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isWideScreen ? 40.0 : 20.0; // تعديل البادينق

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
              vertical: 30,
              horizontal: horizontalPadding), // استخدام البادينق المعدل
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
                  buildTextField(firstNameController, 'الاسم الأول',
                      'أدخل الإسم الأول هنا', true),
                  const SizedBox(height: 16),
                  buildTextField(lastNameController, 'الاسم الأخير',
                      'أدخل الاسم الأخير هنا', true),
                  const SizedBox(height: 16),
                  buildTextField(emailController, 'البريد الإلكتروني',
                      'أدخل البريد الإلكتروني هنا', true),
                  const SizedBox(height: 16),
                  buildTextField(passwordController, 'كلمة المرور',
                      'أدخل كلمة المرور هنا', true),
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
                          if (isValidEmail(emailController.text.trim())) {
                            if (passwordController.text.trim().length >= 6) {
                              try {
                                final success =
                                    await widget.firestoreService.createUser(
                                  firstName: firstNameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                  state: selectedState,
                                  currentEmail: UserSession.email!,
                                  currentPassword: UserSession.password!,
                                );

                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تمت إضافة المسؤول بنجاح'),
                                      backgroundColor: Colors.grey,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'البريد الإلكتروني مستخدم مسبقًا'),
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
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'كلمة المرور يجب أن لا تقل عن 6 ارقام اوحروف'),
                              ));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('البريد الإلكتروني غير صالح'),
                            ));
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
}
