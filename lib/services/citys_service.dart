import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/models/city.dart';
import 'package:gallery_management/models/classification.dart';

class CitysService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<City>> fetchCitys() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('city').get();
      return snapshot.docs.map((doc) {
        return City(id: doc.id, name: doc['name']);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المدن: $e');
    }
  }

  Future<void> addCity(String name) async {
    try {
      await _firestore.collection('city').add({'name': name});
    } catch (e) {
      throw Exception('فشل في إضافة التصنيف: $e');
    }
  }

  Future<void> deleteCity(String classificationId) async {
    final adsQuery = await _firestore
        .collection('2')
        .where('city id',
            isEqualTo: _firestore.collection('city').doc(classificationId))
        .limit(1)
        .get();

    if (adsQuery.docs.isNotEmpty) {
      throw Exception('لا يمكن حذف المدينة لانها مربوطة بمعارض');
    }

    await _firestore.collection('city').doc(classificationId).delete();
  }
}
