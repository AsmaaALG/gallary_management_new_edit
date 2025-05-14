import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

class AddAdminScreen extends StatelessWidget {
  final FirestoreService firestoreService;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  AddAdminScreen({Key? key, required this.firestoreService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة مسؤول جديد',
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
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'يمكنك من خلال هذه الواجهة إضافة مسؤول جديد عبر تعبئة الحقول التالية',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // حقل البريد الإلكتروني
                _buildTextField(emailController, 'البريد الإلكتروني',
                    'أدخل البريد الإلكتروني هنا'),
                const SizedBox(height: 16),

                // حقل الاسم الأول
                _buildTextField(
                    firstNameController, 'الاسم الأول', 'أدخل الاسم الأول هنا'),
                const SizedBox(height: 16),

                // حقل الاسم الأخير
                _buildTextField(lastNameController, 'الاسم الأخير',
                    'أدخل الاسم الأخير هنا'),
                const SizedBox(height: 16),

                // حقل المعرف
                _buildTextField(idController, 'المعرف', 'أدخل المعرف هنا'),
                const SizedBox(height: 30),

                // زر الإضافة
                ElevatedButton(
                  onPressed: () {
                    if (emailController.text.isNotEmpty &&
                        firstNameController.text.isNotEmpty &&
                        lastNameController.text.isNotEmpty &&
                        idController.text.isNotEmpty) {
                      firestoreService.addAdmin(
                        emailController.text.trim(),
                        firstNameController.text.trim(),
                        lastNameController.text.trim(),
                        idController.text.trim(),
                      );
                      Navigator.pop(context); // أغلق النافذة بعد الإضافة
                    } else {
                      // معالجة خطأ إذا كانت الحقول فارغة
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    iconColor: primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'إضافة',
                    style: TextStyle(fontSize: 16, fontFamily: mainFont),
                  ),
                ),
                const SizedBox(height: 10),

                // زر إلغاء
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint) {
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال $label';
        }
        return null;
      },
    );
  }
}
