import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth * 0.05;
    final titleFontSize = screenWidth * 0.045;

    return Directionality(
      textDirection: TextDirection.rtl, // لضبط الاتجاه العام لليمين
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة المسؤولين',
            style: TextStyle(
              fontFamily: mainFont,
              color: Colors.white,
              fontSize: titleFontSize.clamp(14, 18),
            ),
          ),
          backgroundColor: primaryColor,
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: screenWidth * 0.35,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        'إدارة المسؤولين',
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(18, 22),
                          fontFamily: mainFont,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'من خلال هذه الواجهة يمكنك متابعة بيانات جميع المسؤولين الموجودين وتعديلها',
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(12, 14),
                          fontFamily: mainFont,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAdmins(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('حدث خطأ أثناء تحميل البيانات')),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final admins = snapshot.data!.docs;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final admin = admins[index];
                      final data = admin.data() as Map<String, dynamic>;
                      final email = data['email'] ?? 'غير معروف';

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardPadding,
                          vertical: 10,
                        ),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: const Color.fromARGB(255, 218, 142, 146)
                                  .withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          color: const Color.fromARGB(255, 250, 237, 237),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // عرض بيانات المسؤول
                                _buildAdminInfoRow('', email),

                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: secondaryColor),
                                      onPressed: () {
                                        _editAdminDialog(context, admin);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: secondaryColor),
                                      onPressed: () => _confirmDeleteAdmin(
                                          context, admin.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: admins.length,
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () {
            _addAdminDialog(context); // فتح نافذة إضافة
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // دالة مساعدة لعرض صف معلومات المسؤول
  Widget _buildAdminInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // لجعل العناصر في المنتصف
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: mainFont,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: mainFont,
              fontSize: 16,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // نافذة إضافة مسؤول جديد
  Future<void> _addAdminDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final idController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'إضافة مسؤول جديد',
            style: TextStyle(
              fontSize: 16,
              fontFamily: mainFont,
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // كل حقل مع محاذاة يمين
                TextField(
                  controller: emailController,
                  textAlign: TextAlign.right,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني'),
                ),
                TextField(
                  controller: firstNameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الأول'),
                ),
                TextField(
                  controller: lastNameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الأخير'),
                ),
                TextField(
                  controller: idController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'المعرف'),
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
                  color: Color.fromARGB(255, 99, 98, 98),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (emailController.text.isNotEmpty &&
                    firstNameController.text.isNotEmpty &&
                    lastNameController.text.isNotEmpty &&
                    idController.text.isNotEmpty) {
                  _firestoreService.addAdmin(
                    emailController.text.trim(),
                    firstNameController.text.trim(),
                    lastNameController.text.trim(),
                    idController.text.trim(),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                'إضافة',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: mainFont,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة تعديل بيانات مسؤول
  Future<void> _editAdminDialog(
      BuildContext context, QueryDocumentSnapshot admin) async {
    final data = admin.data() as Map<String, dynamic>;
    final emailController = TextEditingController(text: data['email'] ?? '');
    final firstNameController =
        TextEditingController(text: data['first_name'] ?? '');
    final lastNameController =
        TextEditingController(text: data['last_name'] ?? '');
    final idController = TextEditingController(text: data['id'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
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
              children: [
                // الحقول بعد ضبط المحاذاة لليمين
                TextField(
                  controller: emailController,
                  textAlign: TextAlign.right,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني'),
                ),
                TextField(
                  controller: firstNameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الأول'),
                ),
                TextField(
                  controller: lastNameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الأخير'),
                ),
                TextField(
                  controller: idController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'المعرف'),
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
                  idController.text.trim(),
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
        ),
      ),
    );
  }

  // نافذة تأكيد حذف مسؤول
  Future<void> _confirmDeleteAdmin(BuildContext context, String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          content: const Text(
            'هل أنت متأكد من حذف هذا المسؤول؟',
            textAlign: TextAlign.center, // محاذاة أفقيًا في المنتصف
            style: TextStyle(
              fontSize: 14,
              fontFamily: mainFont,
              color: Color.fromARGB(255, 36, 35, 35),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // لجعل الأزرار في المنتصف
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      color: Color.fromARGB(255, 93, 93, 93),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16), // مسافة بين الزرين
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'حذف',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mainFont,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      _firestoreService.deleteAdmin(id);
    }
  }
}
