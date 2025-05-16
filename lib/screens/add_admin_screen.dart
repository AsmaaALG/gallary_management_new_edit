import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

class AddAdminScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const AddAdminScreen({Key? key, required this.firestoreService})
      : super(key: key);

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  int selectedState = 0;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
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
                _buildTextField(emailController, 'البريد الإلكتروني',
                    'أدخل البريد الإلكتروني هنا'),
                const SizedBox(height: 16),
                _buildTextField(
                    passwordController, 'كلمة المرور', 'أدخل كلمة المرور هنا'),
                const SizedBox(height: 16),
                _buildTextField(
                    firstNameController, 'الاسم الأول', 'أدخل الاسم الأول هنا'),
                const SizedBox(height: 16),
                _buildTextField(lastNameController, 'الاسم الأخير',
                    'أدخل الاسم الأخير هنا'),
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
                        value: 0, child: Text('0 - صلاحيات محدودة')),
                    DropdownMenuItem(
                        value: 1, child: Text('1 - صلاحيات كاملة')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedState = value ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isNotEmpty &&
                        passwordController.text.isNotEmpty &&
                        firstNameController.text.isNotEmpty &&
                        lastNameController.text.isNotEmpty) {
                      try {
                        await widget.firestoreService
                            .addAdminWithPasswordAndState(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          firstNameController.text.trim(),
                          lastNameController.text.trim(),
                          selectedState,
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء الإضافة: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'إضافة',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: mainFont,
                        color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
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
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
    );
  }
}
