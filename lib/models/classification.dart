import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Classification {
  final String id;
  final String name;

  Classification({required this.id, required this.name});

  /// حذف تصنيف
  static Future<void> deleteClassification({
    required BuildContext context,
    required String classificationId,
    required List<Classification> classifications,
    required Function(List<Classification>) onUpdate,
    required Classification? selectedClassification,
    required Function(Classification?) onSelectedUpdate,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد أنك تريد حذف هذا التصنيف؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        final adsQuery = await FirebaseFirestore.instance
            .collection('2')
            .where(
              'classification id',
              isEqualTo: FirebaseFirestore.instance
                  .collection('classification')
                  .doc(classificationId),
            )
            .limit(1)
            .get();

        if (adsQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن حذف التصنيف لأنه مرتبط بمعارض'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('classification')
            .doc(classificationId)
            .delete();

        List<Classification> updatedList = [...classifications]
          ..removeWhere((c) => c.id == classificationId);

        onUpdate(updatedList);

        if (selectedClassification?.id == classificationId) {
          onSelectedUpdate(null);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التصنيف بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف التصنيف: ${e.toString()}')),
        );
      }
    }
  }

  /// جلب التصنيفات
  static Future<void> fetchClassifications({
    required BuildContext context,
    required Function(List<Classification>) onFetched,
  }) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('classification').get();

      final classifications = querySnapshot.docs.map((doc) {
        return Classification(
          id: doc.id,
          name: doc['name'],
        );
      }).toList();

      onFetched(classifications);
    } catch (e) {
      print('حدث خطأ أثناء جلب التصنيفات: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب التصنيفات: ${e.toString()}')),
      );
    }
  }
}
