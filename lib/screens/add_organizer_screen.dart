import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/models/user_session.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/build_text_field.dart';
import 'package:gallery_management/widgets/company_dropdown.dart';

class AddOrganizerScreen extends StatefulWidget {
  final String companyId;
  const AddOrganizerScreen({Key? key, required this.companyId}) : super(key: key,);

  @override
  State<AddOrganizerScreen> createState() => _AddOrganizerScreenState();
}

class _AddOrganizerScreenState extends State<AddOrganizerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedCompanyId;

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

  Future<void> _addOrganizer() async {
    if (_formKey.currentState!.validate()) {
      if (!isValidEmail(emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('البريد الإلكتروني غير صالح')),
        );
        return;
      }

      if (passwordController.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور يجب أن لا تقل عن 6 رموز')),
        );
        return;
      }

      // if (selectedCompanyId == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('يرجى اختيار شركة')),
      //   );
      //   return;
      // }

      try {
        final success = await FirestoreService().createOrganizer(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          companyId: widget.companyId,
        );

        if (success) {
          if (UserSession.email != null && UserSession.password != null) {
            await FirebaseAuth.instance.signOut();

            // تعيين تسجيل الجلسة محليًا
            await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: UserSession.email!,
              password: UserSession.password!,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت إضافة المنظم بنجاح'),
              backgroundColor: Colors.grey,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('البريد الإلكتروني مستخدم مسبقًا')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في الإضافة: $e')),
        );
      }
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
            'إضافة منظم جديد',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white),
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
                    'يرجى تعبئة البيانات التالية لإضافة منظم جديد',
                    style: TextStyle(
                        fontFamily: mainFont,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  ),
                  const SizedBox(height: 30),
                  buildTextField(firstNameController, 'الاسم الأول',
                      'أدخل الاسم الأول', true),
                  const SizedBox(height: 16),
                  buildTextField(lastNameController, 'الاسم الأخير',
                      'أدخل الاسم الأخير', true),
                  const SizedBox(height: 16),
                  buildTextField(emailController, 'البريد الإلكتروني',
                      'أدخل البريد الإلكتروني', true),
                  const SizedBox(height: 16),
                  buildTextField(passwordController, 'كلمة المرور',
                      'أدخل كلمة المرور', true),
                  const SizedBox(height: 16),
                  // CompanyDropdown(
                  //   selectedCompanyId: selectedCompanyId,
                  //   onChanged: (value) {
                  //     selectedCompanyId = value;
                  //   },
                  // ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _addOrganizer,
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
