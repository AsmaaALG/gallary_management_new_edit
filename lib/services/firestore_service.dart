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
        'password': password
      });
      return true;
    } catch (e) {
      print("خطأ أثناء إنشاء المستخدم: $e");
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
  ///ادارة الاعلانــــــــــــــات

  // // إضافة إعلان جديد
  // Future<void> addAd(Map<String, dynamic> adData) async {
  //   await _firestore.collection('ads').add(adData);
  // }

  // تحديث إعلان موجود
  Future<void> updateAd(String id, Map<String, dynamic> updatedData) async {
    await _firestore.collection('ads').doc(id).update(updatedData);
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
    });
  }

  // إضافة مسؤول جديد بمعرف يتم إنشاؤه تلقائيًا
  Future<void> addAdminWithPasswordAndState(
    String email,
    String password,
    String firstName,
    String lastName,
    int state,
  ) async {
    try {
      await _firestore.collection('admin').add({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'state': state,
      });
    } catch (e) {
      print('خطأ أثناء إضافة المسؤول: $e');
      rethrow;
    }
  }

// تحديث مسؤول
  Future<void> updateAdmin(
    String adminId,
    String email,
    String firstName,
    String lastName,
    String password,
    int state,
  ) async {
    await _db.collection('admin').doc(adminId).update({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'state': state,
    });
  }

// حذف مسؤول
  Future<void> deleteAdmin(String adminId) async {
    await _db.collection('admin').doc(adminId).delete();
  }

//////////////////////////////////////////
  // دالة لجلب جميع البيانات من جدول
  Future<List<Map<String, dynamic>>> getAllData(String collectionName) async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore.collection(collectionName).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // إضافة المعرف التلقائي إلى البيانات
        data['documentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("خطأ في جلب البيانات: $e");
      return [];
    }
  }

  // دالة لحذف مستند بناءً على المعرف
  Future<void> deleteDocument(String collectionName, String documentId) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).delete();
    } catch (e) {
      print("خطأ في حذف المستند: $e");
    }
  }

  // دالة لجلب بيانات مستند بناءً على المعرف
  Future<Map<String, dynamic>?> getDocumentById(
      String collectionName, String documentId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(collectionName).doc(documentId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("خطأ في جلب المستند: $e");
      return null;
    }
  }

//حذف المعرض والبيانات المرتبطه به

  Future<void> deleteGalleryAndRelatedData(String galleryId) async {
    try {
      // حذف التعليقات الخاصة بالمعرض
      await _firestore
          .collection('reviews')
          .where('gallery id', isEqualTo: galleryId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete(); // حذف كل تعليق مرتبط بالمعرض
        }
      });

      // حذف الزيارات الخاصة بالمعرض
      await _firestore
          .collection('visit')
          .where('galleryId', isEqualTo: galleryId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete(); // حذف كل زيارة مرتبطة بالمعرض
        }
      });

      // حذف الأجنحة المرتبطة بالمعرض
      await _firestore
          .collection('suite')
          .where('gallery id', isEqualTo: galleryId)
          .get()
          .then((snapshot) async {
        for (var doc in snapshot.docs) {
          // حذف الصور الخاصة بكل جناح
          await _firestore
              .collection('suite image')
              .where('suite id', isEqualTo: doc.id)
              .get()
              .then((imageSnapshot) {
            for (var imageDoc in imageSnapshot.docs) {
              imageDoc.reference.delete(); // حذف الصورة
            }
          });

          // // حذف الصور المرتبطة بالأجنحة المحفوظة
          // await _firestore.collection('saved_wing_images')
          //     .where('wingId', isEqualTo: doc.id)
          //     .get()
          //     .then((savedImageSnapshot) {
          //       for (var savedImageDoc in savedImageSnapshot.docs) {
          //         savedImageDoc.reference.delete(); // حذف الصورة المحفوظة
          //       }
          //     });

          doc.reference.delete(); // حذف الجناح
        }
      });

      // حذف المعرض نفسه
      await _firestore.collection('2').doc(galleryId).delete();

      // حذف المعرض من قائمة المفضلة (إذا كان لديك جدول مفضل)
      await _firestore
          .collection('favorite')
          .where('gallery_id', isEqualTo: galleryId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete(); // حذف من المفضلة
        }
      });

      print('تم حذف المعرض وجميع البيانات المتعلقة به بنجاح.');
    } catch (e) {
      print('حدث خطأ أثناء حذف المعرض: $e');
    }
  }

  Future<void> updateGallery(
      String galleryId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('2').doc(galleryId).update(updatedData);
      print('تم تحديث بيانات المعرض بنجاح');
    } catch (e) {
      print('حدث خطأ أثناء تحديث بيانات المعرض: $e');
      throw e; // يمكنك معالجة الخطأ بشكل أكبر إذا لزم الأمر
    }
  }

  Future<void> addData(String collectionPath, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      throw Exception('Failed to add data: $e');
    }
  }

//////////////////////////////////////////////////////////////////
  ///طلبات الحجز
// دالة تجيب الطلبات الخاصة بمعرض معين باستخدام adId
  Future<List<Map<String, dynamic>>> getBookingRequestsForAd(
      String adId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('space_form')
          .where('adId', isEqualTo: adId)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'docId': doc.id, // ← مهم جداً
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print("خطأ أثناء جلب الطلبات: $e");
      return [];
    }
  }

  Future<void> deleteBookingRequest(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('space_form')
          .doc(docId)
          .delete();
    } catch (e) {
      print("خطأ أثناء حذف الطلب: $e");
    }
  }

  ///////////////////////////////////////
  ///الاجنحة
////دالة جلب الأجنحة المرتبطة بمعرض
  Stream<QuerySnapshot> getSuitesForGallery(String galleryId) {
    return _firestore
        .collection('suite')
        .where('gallery id', isEqualTo: galleryId)
        .snapshots();
  }

////
  ///دالة إضافة جناح جديد
  Future<void> addSuite({
    required String name,
    required String description,
    required String imageUrl,
    required String galleryId,
  }) async {
    await _firestore.collection('suite').add({
      'name': name,
      'description': description,
      'main image': imageUrl,
      'gallery id': galleryId,
    });
  }

  ///
  ///دالة حذف جناح وصوره المرتبطة به
  Future<void> deleteSuiteAndImages(String suiteId) async {
    try {
      // حذف صور الجناح
      final images = await _firestore
          .collection('suite image')
          .where('suite id', isEqualTo: suiteId)
          .get();

      for (var imgDoc in images.docs) {
        await imgDoc.reference.delete();
      }

      // حذف الجناح
      await _firestore.collection('suite').doc(suiteId).delete();
    } catch (e) {
      print('حدث خطأ أثناء حذف الجناح وصوره: $e');
    }
  }

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection(collection).add(data);
      print('Document added successfully to $collection');
    } catch (e) {
      print('Error adding document to $collection: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentsByQuery(
    String collectionPath, {
    List<Map<String, dynamic>>? whereFields,
  }) async {
    try {
      Query query = _db.collection(collectionPath);

      // Apply where conditions if provided
      if (whereFields != null) {
        for (var condition in whereFields) {
          String field = condition['field'];
          dynamic value = condition['value'];
          query = query.where(field, isEqualTo: value);
        }
      }

      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting documents: $e');
      return [];
    }
  }
///////////
  ///////////Future<void> addSectionToAd(
  ///////////  String adId, Map<String, dynamic> sectionData) async {
  /////////// final sectionRef = FirebaseFirestore.instance
///////////.collection('ads')
  ///////////  .doc(adId)
  ///////////  .collection('sections')
  ///////////  .doc(); // auto-generated ID

  ///////////await sectionRef.set(sectionData);
  /////////// }
}
