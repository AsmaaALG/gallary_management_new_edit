import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/add_admin_screen.dart';
import 'package:gallery_management/screens/Admin/main_screen.dart';
import 'package:gallery_management/screens/signIn_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/widgets/main_card.dart';

class AdminManagementScreen2 extends StatefulWidget {
  const AdminManagementScreen2({super.key});

  @override
  State<AdminManagementScreen2> createState() => _AdminManagementScreen2State();
}

class _AdminManagementScreen2State extends State<AdminManagementScreen2> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admin').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          }

          final cards = snapshot.data!.docs.map((doc) {
            final documentId = doc.id;

            Future<void> delete() {
              return _firestoreService.deleteAdmin(doc.id);
            }

            return MainCard(
              title: doc['email'],
              buttons: [
                {
                  'icon': Icons.edit,
                  'action': () {
                    _editAdminDialog(context, doc);
                  },
                },
                {
                  'icon': Icons.delete_rounded,
                  'action': () {
                    confirmDelete(context, () async {
                      final user = FirebaseAuth.instance.currentUser;

                      final deletedEmail = doc['email'];

                      // تنفيذ الحذف من قاعدة البيانات
                      await _firestoreService.deleteAdmin(doc.id);

                      // تحقق إذا كان المحذوف هو المستخدم الحالي
                      if (user != null && deletedEmail == user.email) {
                        // تسجيل الخروج
                        await FirebaseAuth.instance.signOut();

                        // التوجه لواجهة تسجيل الدخول وحذف سجل التنقل
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignInScreen()),
                            (route) => false,
                          );
                        }
                      }
                    });
                  },
                }
              ],
            );
          }).toList();

          return MainScreen(
            title: 'إدارة المسؤولين',
            description:
                'من خلال هذه الواجهة يمكنك متابعة بيانات جميع المسؤولين الموجودين وتعديلها',
            cards: cards,
            addScreen: AddAdminScreen(
              firestoreService: _firestoreService,
            ),
          );
        },
      ),
    );
  }

  // نافذة تعديل بيانات المسؤول
  Future<void> _editAdminDialog(
      BuildContext context, QueryDocumentSnapshot admin) async {
    final data = admin.data() as Map<String, dynamic>;
    final emailController = TextEditingController(text: data['email'] ?? '');
    final firstNameController =
        TextEditingController(text: data['first_name'] ?? '');
    final lastNameController =
        TextEditingController(text: data['last_name'] ?? '');
    final passwordController =
        TextEditingController(text: data['password'] ?? '');
    int stateValue = data['state'] ?? 0;

    bool obscurePassword = true;

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تعديل بيانات المسؤول',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: mainFont,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني'),
                        readOnly: true,
                        enabled: false,
                      ),
                      TextFormField(
                        controller: firstNameController,
                        textAlign: TextAlign.right,
                        decoration:
                            const InputDecoration(labelText: 'الاسم الأول'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال الاسم الأول';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: lastNameController,
                        textAlign: TextAlign.right,
                        decoration:
                            const InputDecoration(labelText: 'الاسم الأخير'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال الاسم الأخير';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال كلمة المرور';
                          } else if (value.trim().length < 6) {
                            return 'كلمة المرور يجب ألا تقل عن 6 خانات';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<int>(
                        value: stateValue,
                        decoration:
                            const InputDecoration(labelText: 'الصلاحيات'),
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
                          if (value != null) {
                            setState(() {
                              stateValue = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      color: Color.fromARGB(255, 104, 104, 104),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _firestoreService.updateAdmin(
                        admin.id,
                        firstNameController.text.trim(),
                        lastNameController.text.trim(),
                        passwordController.text.trim(),
                        stateValue,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث بيانات المسؤول بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'تحديث',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
