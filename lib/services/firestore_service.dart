import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isEmailAlreadyExists(String email) async {
    final querySnapshot = await _firestore
        .collection('admin')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Sign up باستخدام Auth
  Future<bool> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // إنشاء المستخدم في Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // جلب UID الخاص بالمستخدم
      String uid = userCredential.user!.uid;

      // تخزين البيانات في Firestore
      final docRef =
          _firestore.collection('admin').doc(uid); // استخدام الـ UID كـ ID
      await docRef.set({
        'id': uid, // حفظ الـ ID داخل بيانات المستخدم
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
      return true;
    } catch (e) {
      print("خطأ أثناء إنشاء المستخدم: $e");
      return false;
    }
  }
}
