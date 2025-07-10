import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/confirm_ads_request.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AdsRequestManagementScreen extends StatefulWidget {
  const AdsRequestManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdsRequestManagementScreen> createState() =>
      _AdsRequestManagementScreenState();
}

class _AdsRequestManagementScreenState
    extends State<AdsRequestManagementScreen> {
  Future<List<QueryDocumentSnapshot>> fetchPendingRequests() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ads_requests')
        .where('status', isEqualTo: 'pending')
        .get();

    // فلترة الطلبات التي تحتوي على requested_at
    List<QueryDocumentSnapshot> validDocs =
        snapshot.docs.where((doc) => doc['requested_at'] != null).toList();

    // ترتيبهم تنازليًا (الأحدث أولاً)
    validDocs.sort((a, b) {
      Timestamp aTime = a['requested_at'];
      Timestamp bTime = b['requested_at'];
      return bTime.compareTo(aTime);
    });

    return validDocs;
  }

  Future<String> getClassificationName(dynamic ref) async {
    if (ref == null) return '---';
    try {
      if (ref is DocumentReference) {
        final doc = await ref.get();
        return doc['name'] ?? '---';
      }
      if (ref is String) {
        final doc = await FirebaseFirestore.instance.doc(ref).get();
        return doc['name'] ?? '---';
      }
      return '---';
    } catch (e) {
      return '---';
    }
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف',
            style: TextStyle(
                fontFamily: mainFont,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟',
            style: TextStyle(fontFamily: mainFont, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: mainFont)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('ads_requests')
                  .doc(docId)
                  .delete();
              Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('حذف',
                style:
                    TextStyle(fontFamily: mainFont, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget buildAdCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final requestedAt = (data['requested_at'] as Timestamp?)?.toDate();
    final formattedRequestedAt = requestedAt != null
        ? DateFormat('dd-MM-yyyy').format(requestedAt)
        : '---';

    return FutureBuilder<String>(
      future: getClassificationName(data['classification id']),
      builder: (context, snapshot) {
        final classificationName = snapshot.data ?? '---';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تاريخ الطلب: $formattedRequestedAt',
                    style: const TextStyle(
                        fontFamily: mainFont,
                        color: Color.fromARGB(255, 133, 132, 132))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ' عنوان الإعلان : ${data['title'] ?? 'بدون عنوان'}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontFamily: mainFont,
                          fontWeight: FontWeight.bold),
                      maxLines: 5, // عدد الأسطر القصوى
                      overflow: TextOverflow.ellipsis,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: primaryColor),
                      onPressed: () => _showDeleteConfirmation(doc.id),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'الشركة: ${data['company_name'] ?? '---'}',
                  style: const TextStyle(fontFamily: mainFont),
                  maxLines: 5, // عدد الأسطر القصوى
                  overflow: TextOverflow.ellipsis,
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(
                          'city') // تأكد من اسم المجموعة عندك في Firebase
                      .doc(data['city']) // هذا String ID
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('المنطقة: جارٍ التحميل...',
                          style: TextStyle(fontFamily: mainFont));
                    } else if (snapshot.hasData && snapshot.data != null) {
                      final cityName = snapshot.data!.get('name') ?? '---';
                      return Text('المنطقة: $cityName',
                          style: const TextStyle(fontFamily: mainFont));
                    } else {
                      return const Text('المنطقة: ---',
                          style: TextStyle(fontFamily: mainFont));
                    }
                  },
                ),
                Text(
                  'الوصف: ${data['description'] ?? '---'}',
                  style: const TextStyle(fontFamily: mainFont),
                  maxLines: 5, // عدد الأسطر القصوى
                  overflow: TextOverflow.ellipsis,
                ),
                Text('التصنيف: $classificationName',
                    style: const TextStyle(fontFamily: mainFont)),
                if (data['suites'] != null &&
                    data['suites'] is List &&
                    data['suites'].isNotEmpty) ...[
                  // const SizedBox(height: 12),
                  Text('عدد الأجنحة: ${data['suites'].length}',
                      style: const TextStyle(fontFamily: mainFont)),
                ],
                Text('تاريخ البداية: ${data['start date'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                Text('تاريخ النهاية: ${data['end date'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                Text('تاريخ  إيقاف الإعلان: ${data['stopAd'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                if (data['map'] != null) ...[
                  const SizedBox(height: 10),
                  const Text('صورة الخريطة:',
                      style: TextStyle(fontFamily: mainFont)),
                  const SizedBox(height: 5),
                  Image.network(data['map'], height: 150),
                ],
                if (data['image url'] != null) ...[
                  const SizedBox(height: 10),
                  const Text('صورة الإعلان:',
                      style: TextStyle(fontFamily: mainFont)),
                  const SizedBox(height: 5),
                  Image.network(data['image url'], height: 150),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        confirmAdRequest(
                          context: context,
                          actionType: 'accept',
                          onConfirm: () async {
                            final companyId = data['company_id'];
                            final adData = {
                              'title': data['title'],
                              'company_id': data['company_id'],
                              'description': data['description'],
                              'location': data['location'],
                              'classification id': data['classification id'],
                              'start date': data['start date'],
                              'end date': data['end date'],
                              'stopAd': data['stopAd'],
                              'image url': data['image url'],
                              'map': data['map'],
                              'suites': data['suites'],
                              'created_at': Timestamp.now(),
                              'status': 'active',
                            };

                            // إضافة الإعلان في جدول ads العام
                            await FirebaseFirestore.instance
                                .collection('ads')
                                .add(adData);

                            // إذا كان عنده company_id نضيفه أيضًا في ads الخاصة بالشركة
                            if (companyId != null &&
                                companyId.toString().isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection(
                                      'company') // أو استبدلها لو اسم مجموعة المنظم مختلف
                                  .doc(companyId)
                                  .collection('ads')
                                  .add(adData);
                            }

                            // تحديث حالة الطلب
                            await FirebaseFirestore.instance
                                .collection('ads_requests')
                                .doc(doc.id)
                                .update({'status': 'accepted'});

                            setState(() {});
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('قبول الطلب',
                          style: TextStyle(
                              fontFamily: mainFont,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () {
                        confirmAdRequest(
                          context: context,
                          actionType: 'reject',
                          onConfirm: () async {
                            await FirebaseFirestore.instance
                                .collection('ads_requests')
                                .doc(doc.id)
                                .update({'status': 'rejected'});

                            setState(() {});
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('رفض الطلب',
                          style: TextStyle(
                              fontFamily: mainFont,
                              color: primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'طلبات الإعلانات',
            style: TextStyle(
              color: Colors.white,
              fontFamily: mainFont,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 100 : 20, vertical: 20),
          child: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: fetchPendingRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('لا توجد طلبات إعلانات جديدة',
                        style: TextStyle(fontFamily: mainFont, fontSize: 15)));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) =>
                      buildAdCard(snapshot.data![index]),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
