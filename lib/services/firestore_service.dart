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

//////////////////////////////////////////////////////////////////////////
  ///ادارة الاعلانــــــــــــــات
  // جلب جميع الإعلانات
  Stream<QuerySnapshot> getAds() {
    return _firestore.collection('ads').snapshots();
  }

  // إضافة إعلان جديد
  Future<void> addAd(Map<String, dynamic> adData) async {
    await _firestore.collection('ads').add(adData);
  }

  // تحديث إعلان موجود
  Future<void> updateAd(String id, Map<String, dynamic> updatedData) async {
    await _firestore.collection('ads').doc(id).update(updatedData);
  }

  // حذف إعلان
  Future<void> deleteAd(String id) async {
    await _firestore.collection('ads').doc(id).delete();
  }

  // أضف هذه الدالة إلى ملف firestore_service.dart
  Future<Map<String, dynamic>?> getAdById(String id) async {
    try {
      final doc = await _firestore.collection('ads').doc(id).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print("Error getting ad: $e");
      return null;
    }
  }

  //////////////////////////////////////////////////////////////////
  ///المسؤوليـــــــــــن
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// جلب المسؤولين
  Stream<QuerySnapshot> getAdmins() {
    return _db.collection('admin').snapshots();
  }

// إضافة مسؤول
  Future<void> addAdmin(
      String email, String firstName, String lastName, String id) async {
    await _db.collection('admin').add({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'id': id,
    });
  }

// تحديث مسؤول
  Future<void> updateAdmin(String adminId, String email, String firstName,
      String lastName, String id) async {
    await _db.collection('admin').doc(adminId).update({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'id': id,
    });
  }

// حذف مسؤول
  Future<void> deleteAdmin(String adminId) async {
    await _db.collection('admin').doc(adminId).delete();
  }
}
