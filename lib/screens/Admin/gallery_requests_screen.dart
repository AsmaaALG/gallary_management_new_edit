import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../widgets/confirm_request.dart';

class GalleryRequestManagementScreen extends StatefulWidget {
  const GalleryRequestManagementScreen({Key? key}) : super(key: key);

  @override
  State<GalleryRequestManagementScreen> createState() =>
      _GalleryRequestManagementScreenState();
}

class _GalleryRequestManagementScreenState
    extends State<GalleryRequestManagementScreen> {
  Future<List<QueryDocumentSnapshot>> fetchPendingRequests() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('gallery_requests')
        .where('status', isEqualTo: 'pending')
        .get();

    List<QueryDocumentSnapshot> validDocs =
        snapshot.docs.where((doc) => doc['requested_at'] != null).toList();

    validDocs.sort((a, b) {
      Timestamp aTime = a['requested_at'];
      Timestamp bTime = b['requested_at'];
      return bTime.compareTo(aTime); // الأحدث أولًا
    });

    return validDocs;
  }

  Future<void> updateRequestStatus({
    required String docId,
    required String newStatus,
    required Map<String, dynamic> data,
  }) async {
    await FirebaseFirestore.instance
        .collection('gallery_requests')
        .doc(docId)
        .update({'status': newStatus});

    if (newStatus == 'accepted') {
      await FirebaseFirestore.instance.collection('galleries').add({
        'title': data['title'],
        'description': data['description'],
        'city': data['city'],
        'company_id': data['company_id'],
        'company_name': data['company_name'],
        'location': data['location'],
        'classification id': data['classification id'],
        'start date': data['start date'],
        'end date': data['end date'],
        'suites_count': data['suites_count'],
        'image url': data['image url'],
        'map': data['map'],
        'created_at': Timestamp.now(),
      });
    }

    setState(() {});
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف',
            style:
                TextStyle(fontFamily: mainFont, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟',
            style: TextStyle(fontFamily: mainFont)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: mainFont)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('gallery_requests')
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

  Widget buildRequestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final requestedAt = (data['requested_at'] as Timestamp?)?.toDate();
    final formattedRequestedAt = requestedAt != null
        ? DateFormat('dd-MM-yyyy').format(requestedAt)
        : '---';

    return FutureBuilder<DocumentSnapshot>(
      future: (data['classification id'] != null)
          ? (data['classification id'] as DocumentReference).get()
          : Future.value(null),
      builder: (context, classificationSnapshot) {
        final classificationName = classificationSnapshot.hasData &&
                classificationSnapshot.data != null
            ? (classificationSnapshot.data!.data()
                    as Map<String, dynamic>)['name'] ??
                '---'
            : '---';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('city')
              .doc(data['city'])
              .get(),
          builder: (context, citySnapshot) {
            final cityName = citySnapshot.hasData
                ? citySnapshot.data!.get('name') ?? '---'
                : '---';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                          ' عنوان المعرض : ${data['title'] ?? 'بدون عنوان'}',
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
                    Text('المنطقة: $cityName',
                        style: const TextStyle(fontFamily: mainFont)),
                    Text(
                      'الوصف: ${data['description'] ?? '---'}',
                      style: const TextStyle(fontFamily: mainFont),
                      maxLines: 5, // عدد الأسطر القصوى
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('التصنيف: $classificationName',
                        style: const TextStyle(fontFamily: mainFont)),
                    Text('عدد الأجنحة: ${data['suites_count'] ?? 0}',
                        style: const TextStyle(fontFamily: mainFont)),
                    const SizedBox(height: 10),
                    Text('تاريخ البداية: ${data['start date'] ?? '---'}',
                        style: const TextStyle(fontFamily: mainFont)),
                    Text('تاريخ النهاية: ${data['end date'] ?? '---'}',
                        style: const TextStyle(fontFamily: mainFont)),
                    if (data['map'] != null)
                      TextButton(
                        onPressed: () async {
                          final url = Uri.parse(data['map']);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text('عرض الخريطة',
                            style: TextStyle(
                                fontFamily: mainFont,
                                color: primaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    if (data['image url'] != null) ...[
                      const SizedBox(height: 10),
                      const Text('صورة الغلاف:',
                          style: TextStyle(fontFamily: mainFont)),
                      const SizedBox(height: 5),
                      Image.network(data['image url'], height: 150),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            confirmRequest(
                              context: context,
                              actionType: 'accept',
                              onConfirm: () async {
                                await updateRequestStatus(
                                    docId: doc.id,
                                    newStatus: 'accepted',
                                    data: data);
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
                            confirmRequest(
                              context: context,
                              actionType: 'reject',
                              onConfirm: () async {
                                await updateRequestStatus(
                                    docId: doc.id,
                                    newStatus: 'rejected',
                                    data: data);
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
            'طلبات إنشاء معرض',
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
                    child: Text('لا توجد طلبات إنشاء معارض',
                        style: TextStyle(fontFamily: mainFont, fontSize: 15)));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) =>
                      buildRequestCard(snapshot.data![index]),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
