import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/models/classification.dart';

class ClassificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Classification>> fetchClassifications() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('classification').get();
      return snapshot.docs.map((doc) {
        return Classification(id: doc.id, name: doc['name']);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب التصنيفات: $e');
    }
  }

  Future<void> addClassification(String name) async {
    try {
      await _firestore.collection('classification').add({'name': name});
    } catch (e) {
      throw Exception('فشل في إضافة التصنيف: $e');
    }
  }

  Future<void> deleteClassification(String classificationId) async {
    final adsQuery = await _firestore
        .collection('2')
        .where('classification id',
            isEqualTo:
                _firestore.collection('classification').doc(classificationId))
        .limit(1)
        .get();

    if (adsQuery.docs.isNotEmpty) {
      throw Exception('لا يمكن حذف التصنيف لأنه مرتبط بمعارض');
    }

    await _firestore
        .collection('classification')
        .doc(classificationId)
        .delete();
  }
}
