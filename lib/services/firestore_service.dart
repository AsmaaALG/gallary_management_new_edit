import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gallery_management/models/ad_model.dart';
import 'package:gallery_management/models/user_session.dart';
import 'package:intl/intl.dart';

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

  Future<bool> createUser({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required int state,
  required String currentEmail,
  required String currentPassword,
}) async {
  try {
    UserCredential newUser =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);

    await _firestore.collection('admin').doc(newUser.user!.uid).set({
      'id': newUser.user!.uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'state': state,
    });

    await _auth.signOut();

    await _auth.signInWithEmailAndPassword(
      email: currentEmail,
      password: currentPassword,
    );

    return true;
  } catch (e) {
    print("خطأ أثناء إنشاء المستخدم: $e");
    return false;
  }
}

////////////////////////////
  Future<bool> createOrganizer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String companyId,
    required String currentEmail,
  required String currentPassword,
  }) async {
    try {
      // حفظ الجلسة الحالية قبل التسجيل
      // final currentUser = FirebaseAuth.instance.currentUser;
      // final currentEmail = UserSession.email;
      // final currentPassword = UserSession.password;

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('Organizer').doc(uid).set({
        'id': uid,
        'first name': firstName,
        'last name': lastName,
        'email': email,
        'password': password,
        'company_id': companyId,
      });

      // // إعادة تسجيل الدخول بالحساب السابق (الأدمن)
      // if (currentEmail != null && currentPassword != null) {
      //   await FirebaseAuth.instance.signOut(); // <- مهم جدًا
      //   await FirebaseAuth.instance.signInWithEmailAndPassword(
      //     email: currentEmail,
      //     password: currentPassword,
      //   );
      // }
    await _auth.signOut();

    await _auth.signInWithEmailAndPassword(
      email: currentEmail,
      password: currentPassword,
    );

      return true;
    } catch (e) {
      print("خطأ أثناء إنشاء المنظم: $e");
      return false;
    }
  }

//////////////////////////////////////////////
  Future<String?> checkEmailLocation(String email) async {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: email)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      return 'admin';
    }

    final organizerSnapshot = await FirebaseFirestore.instance
        .collection('Organizer')
        .where('email', isEqualTo: email)
        .get();

    if (organizerSnapshot.docs.isNotEmpty) {
      return 'organizer';
    }

    return null;
  }

//////////////////////////////////////////////////////////////////////////
  ///ادارة الاعلانــــــــــــــات
  Future<void> updateAd(String id, Map<String, dynamic> updatedData) async {
    await _firestore.collection('ads').doc(id).update(updatedData);
  }

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

  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update(data);
  }

  //////////////////////////////////////////////////////////////////
  ///المسؤوليـــــــــــن
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// تحديث مسؤول
  Future<void> updateAdmin(
    String adminId,
    String firstName,
    String lastName,
    String password,
    int state,
  ) async {
    await _db.collection('admin').doc(adminId).update({
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'state': state,
    });
  }

// حذف مسؤول

  Future<void> deleteAdmin(String adminId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    final adminDoc = await _db.collection('admin').doc(adminId).get();
    final deletedEmail = adminDoc.data()?['email'];

    await _db.collection('admin').doc(adminId).delete();

    if (currentUser != null && currentUser.email == deletedEmail) {
      await FirebaseAuth.instance.signOut();
    }
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
          doc.reference.delete(); 
        }
      });

      // حذف الزيارات الخاصة بالمعرض
      await _firestore
          .collection('visit')
          .where('galleryId', isEqualTo: galleryId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete(); 
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

          doc.reference.delete(); // حذف الجناح
        }
      });

      // حذف الشركاء المرتبطين بالمعرض
      await _firestore
          .collection('partners')
          .where('gallery id', isEqualTo: galleryId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete(); 
        }
      });

      // حذف المعرض نفسه
      await _firestore.collection('2').doc(galleryId).delete();

      // حذف المعرض من قائمة المفضلة
      await _firestore
          .collection('favorite')
          .where('gallery_id', isEqualTo: galleryId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete(); 
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
      throw e; 
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

  Future<void> addAcceptedRequest(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('accepted_requests').add(data);
  }

// دالة تجيب الطلبات الخاصة بمعرض معين باستخدام adId
  Future<List<Map<String, dynamic>>> getBookingRequestsForAd(
      String adId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('space_form')
          .where('adId', isEqualTo: adId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return {
          'docId': doc.id,
          ...data,
          'accepted': data['accepted'] ?? false,
          'disabled': data['disabled'] ?? false,
        };
      }).toList();
    } catch (e) {
      print("خطأ أثناء جلب الطلبات: $e");
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamBookingRequestsForAd(String adId) {
    return FirebaseFirestore.instance
        .collection('bookingRequests')
        .where('adId', isEqualTo: adId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['docId'] = doc.id; 
              return data;
            }).toList());
  }

  Future<void> updateSuiteStatusInAd(String adId, String suiteName,
      {bool available = false}) async {
    final adRef = FirebaseFirestore.instance.collection('ads').doc(adId);
    final adDoc = await adRef.get();

    if (adDoc.exists) {
      List<dynamic> suites = adDoc['suites'] ?? [];
      for (var suite in suites) {
        if (suite['name'] == suiteName) {
          suite['status'] = available ? 0 : 1;
          break;
        }
      }
      await adRef.update({'suites': suites});
    }
  }

//  تعطيل باقي الطلبات التي تطلب نفس الجناح
  Future<void> disableOtherRequestsForSameSuite(
      String adId, String suiteName, String currentDocId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('space_form')
        .where('adId', isEqualTo: adId)
        .get();

    for (var doc in snapshot.docs) {
      if (doc.id != currentDocId && doc['selectedSuite']['name'] == suiteName) {
        await doc.reference.update({'disabled': true});
      }
    }
  }

//  تعليم الطلب الحالي بأنه مقبول
  Future<void> markRequestAsAccepted(String docId) async {
    await FirebaseFirestore.instance
        .collection('space_form')
        .doc(docId)
        .update({'accepted': true});
  }

  /// إعادة تفعيل الطلبات الأخرى التي تطلب نفس الجناح
  Future<void> enableOtherRequestsForSameSuite(
      String adId, String suiteName) async {
    try {
      final query = await _firestore
          .collection('space_form')
          .where('adId', isEqualTo: adId)
          .where('selectedSuite.name', isEqualTo: suiteName)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'disabled': false});
      }
    } catch (e) {
      print("خطأ أثناء إعادة تفعيل الطلبات: $e");
    }
  }

  /// إزالة حالة القبول من الطلب المحدد
  Future<void> unmarkRequestAsAccepted(String docId) async {
    try {
      await _firestore.collection('space_form').doc(docId).update({
        'accepted': false,
        'disabled': false,
      });
    } catch (e) {
      print("فشل إزالة حالة القبول: $e");
    }
  }
Future<String?> getGalleryIdByAdId(String adId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('2')
      .where('ad_id', isEqualTo: adId)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id;
  }
  return null; // لم يتم فتح المعرض بعد
}

  Future<List<Map<String, dynamic>>> getAcceptedBookingRequests(
      String adId) async {
    try {
      final query = await _firestore
          .collection('space_form')
          .where('adId', isEqualTo: adId)
          .where('accepted', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => {
                'docId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print("خطأ أثناء جلب الطلبات المقبولة: $e");
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

  /*================  الشركاء partners ================*/
  Stream<QuerySnapshot> getPartnersForGallery(String galleryId) {
    return _firestore
        .collection('partners')
        .where('gallery id', isEqualTo: galleryId)
        .snapshots();
  }

  Future<void> addPartner({
    required String name,
    required String imageUrl,
    required String galleryId,
  }) async {
    await _firestore.collection('partners').add({
      'name': name,
      'image': imageUrl,
      'gallery id': galleryId,
    });
  }

  Future<void> updatePartner(String partnerId,
      {required String name, required String imageUrl}) async {
    await _firestore.collection('partners').doc(partnerId).update({
      'name': name,
      'image': imageUrl,
    });
  }

  Future<void> deletePartner(String partnerId) async {
    await _firestore.collection('partners').doc(partnerId).delete();
  }

  /////////////////////////////////////////////////////////////////
  ///

  Future<void> convertAdsToGalleries() async {
    final now = DateTime.now();
    final adsRef = FirebaseFirestore.instance.collection('ads');
    final galleriesRef = FirebaseFirestore.instance.collection('2');
    final notificationsRef =
        FirebaseFirestore.instance.collection('notifications');
    final spaceFormRef = FirebaseFirestore.instance.collection('space_form');
    final suiteRef = FirebaseFirestore.instance.collection('suite');

    try {
      final adsSnapshot = await adsRef.get();

      for (final doc in adsSnapshot.docs) {
        final ad = AdModel.fromMap(doc.data(), doc.id);

        // تحويل الإعلان إلى معرض عند تاريخ البداية 
        if (ad.startDate.isNotEmpty) {
          try {
            final startDate = DateFormat('dd-MM-yyyy').parse(ad.startDate);

            if (!now.isBefore(startDate)) {
              // تحقق إن تم تحويل الإعلان من قبل إلى معرض
              final existingGallery = await galleriesRef
                  .where('ad_id', isEqualTo: ad.id)
                  .limit(1)
                  .get();

              if (existingGallery.docs.isEmpty) {
                // تحويل الإعلان إلى معرض
                final galleryDoc = await galleriesRef.add({
                  'title': ad.title,
                  'description': ad.description,
                  'image url': ad.imageUrl,
                  'location': ad.location,
                  'start date': ad.startDate,
                  'end date': ad.endDate,
                  'QR code': ad.qrCode ?? '',
                  'classification id': ad.classificationId,
                  'company_id': ad.company_id,
                  'map': ad.map,
                  'city': ad.city,
                  'ad_id': ad.id,
                });

                print("تم تحويل الإعلان '${ad.id}' إلى معرض.");

                // تحويل الطلبات المقبولة إلى أجنحة 
                final acceptedForms = await spaceFormRef
                    .where('accepted', isEqualTo: true)
                    .where('adId', isEqualTo: ad.id)
                    .get();

                for (final formDoc in acceptedForms.docs) {
                  final data = formDoc.data();
                  final selectedSuite = data['selectedSuite'];

                  await suiteRef.add({
                    'name': data['wingName'] ?? 'جناح بدون اسم',
                    'description': data['description'] ?? '',
                    'price': int.tryParse(selectedSuite['price'] ?? '0') ?? 0,
                    'size': int.tryParse(selectedSuite['area'] ?? '0') ?? 0,
                    'title on map': selectedSuite['name'] ?? '',
                    'gallery id': galleryDoc.id,
                  });

                  // حذف الطلب بعد التحويل
                  await spaceFormRef.doc(formDoc.id).delete();

                  print("تم تحويل الطلب '${formDoc.id}' إلى جناح وحذفه.");
                }
              } else {
                final gallery = await galleriesRef
                    .where('ad_id', isEqualTo: ad.id)
                    .limit(1)
                    .get();
                final galleryId;

                if (gallery.docs.isNotEmpty) {
                  galleryId = gallery.docs.first.id;
                } else {
                  galleryId = null;
                }

                final acceptedForms = await spaceFormRef
                    .where('accepted', isEqualTo: true)
                    .where('adId', isEqualTo: ad.id)
                    .get();

                for (final formDoc in acceptedForms.docs) {
                  final data = formDoc.data();
                  final selectedSuite = data['selectedSuite'];

                  await suiteRef.add({
                    'name': data['wingName'] ?? 'جناح بدون اسم',
                    'description': data['description'] ?? '',
                    'price': int.tryParse(selectedSuite['price'] ?? '0') ?? 0,
                    'size': int.tryParse(selectedSuite['area'] ?? '0') ?? 0,
                    'title on map': selectedSuite['name'] ?? '',
                    'gallery id': galleryId ?? '',
                  });

                  // حذف الطلب بعد التحويل
                  await spaceFormRef.doc(formDoc.id).delete();

                  print("تم تحويل الإعلان '${ad.id}' مسبقًا.");
                }
              }
            }
          } catch (e) {
            print("خطأ في تاريخ البداية للإعلان '${ad.id}': $e");
          }
        }

        //حذف الإعلان عند الوصول لتاريخ stopAd 
        if (ad.stopAd.isNotEmpty) {
          try {
            final stopDate = DateFormat('dd-MM-yyyy').parse(ad.stopAd);

            if (!now.isBefore(stopDate)) {
              //  حذف الإعلان
              await adsRef.doc(ad.id).delete();

              // حذف الإشعارات المرتبطة
              final notifSnapshot =
                  await notificationsRef.where('ad_id', isEqualTo: ad.id).get();

              for (final notifDoc in notifSnapshot.docs) {
                await notificationsRef.doc(notifDoc.id).delete();
              }

              // حذف الطلبات المرتبطة (space_form)
              final formsSnapshot = await FirebaseFirestore.instance
                  .collection('space_form')
                  .where('adId', isEqualTo: ad.id)
                  .get();

              for (final formDoc in formsSnapshot.docs) {
                await FirebaseFirestore.instance
                    .collection('space_form')
                    .doc(formDoc.id)
                    .delete();
              }

              print(
                  "تم حذف الإعلان '${ad.id}'، الإشعارات، والطلبات المرتبطة به.");
            }
          } catch (e) {
            print("خطأ في تاريخ stopAd للإعلان '${ad.id}': $e");
          }
        }
      }
    } catch (e) {
      print("خطأ أثناء تنفيذ المعالجة: $e");
    }
  }
}
