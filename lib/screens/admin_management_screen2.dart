import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/add_admin_screen.dart';
import 'package:gallery_management/screens/main_screen.dart';
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
                      await _firestoreService.deleteAdmin(doc.id);
                    });
                  },
                },
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      textAlign: TextAlign.right,
                      decoration:
                          const InputDecoration(labelText: 'البريد الإلكتروني'),
                    ),
                    TextField(
                      controller: firstNameController,
                      textAlign: TextAlign.right,
                      decoration:
                          const InputDecoration(labelText: 'الاسم الأول'),
                    ),
                    TextField(
                      controller: lastNameController,
                      textAlign: TextAlign.right,
                      decoration:
                          const InputDecoration(labelText: 'الاسم الأخير'),
                    ),
                    TextField(
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
                    ),
                    DropdownButtonFormField<int>(
                      value: stateValue,
                      decoration: const InputDecoration(labelText: 'الصلاحيات'),
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
                    _firestoreService.updateAdmin(
                      admin.id,
                      emailController.text.trim(),
                      firstNameController.text.trim(),
                      lastNameController.text.trim(),
                      passwordController.text.trim(),
                      stateValue,
                    );
                    Navigator.pop(ctx);
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
