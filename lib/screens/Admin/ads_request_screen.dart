import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/confirm_ads_request.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

    List<QueryDocumentSnapshot> validDocs =
        snapshot.docs.where((doc) => doc['requested_at'] != null).toList();

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
                    Expanded(
                      child: Text(
                        'عنوان الإعلان: ${data['title'] ?? 'بدون عنوان'}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold),
                        softWrap: true,
                      ),
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
                  softWrap: true,
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('city')
                      .doc(data['city'])
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
                const SizedBox(height: 8),
                Text(
                  'الوصف: ${data['description'] ?? '---'}',
                  style: const TextStyle(fontFamily: mainFont),
                  softWrap: true,
                ),
                const SizedBox(height: 8),
                Text('التصنيف: $classificationName',
                    style: const TextStyle(fontFamily: mainFont)),
                if (data['suites'] != null &&
                    data['suites'] is List &&
                    data['suites'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('عدد الأجنحة: ${data['suites'].length}',
                      style: const TextStyle(fontFamily: mainFont)),
                ],
                const SizedBox(height: 8),
                Text('تاريخ البداية: ${data['start date'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                const SizedBox(height: 8),
                Text('تاريخ النهاية: ${data['end date'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                const SizedBox(height: 8),
                Text('تاريخ إيقاف الإعلان: ${data['stopAd'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                if (data['map'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextButton(
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
                  ),
                if (data['image url'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextButton(
                      onPressed: () async {
                        final url = Uri.parse(data['image url']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text('عرض صورة الغلاف',
                          style: TextStyle(
                              fontFamily: mainFont,
                              color: primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 20),
                Column(
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
                              'city': data['city'],
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

                            if (companyId != null &&
                                companyId.toString().isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('company')
                                  .doc(companyId)
                                  .collection('ads')
                                  .add(adData);
                            }

                            DocumentReference adRef = await FirebaseFirestore
                                .instance
                                .collection('ads')
                                .add(adData);

                            String adId = adRef.id;
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .add({
                              'title': adData['title'],
                              'body': adData['description'],
                              'timestamp': FieldValue.serverTimestamp(),
                              'ad_id': adId,
                              'seenBy': [],
                            });

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
                        side: const BorderSide(
                            color: Color.fromARGB(255, 244, 194, 185)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40)),
                        minimumSize: const Size(
                            double.infinity, 48), 
                      ),
                      child: const Text('قبول الطلب',
                          style: TextStyle(
                              fontFamily: mainFont,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12), 
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
                        side: const BorderSide(
                            color: Color.fromARGB(255, 244, 194, 185)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40)),
                        minimumSize: const Size(
                            double.infinity, 48), 
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
