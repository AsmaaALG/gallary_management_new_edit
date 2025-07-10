import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

class MyGalleryRequestsScreen extends StatefulWidget {
  const MyGalleryRequestsScreen({super.key});

  @override
  State<MyGalleryRequestsScreen> createState() =>
      _MyGalleryRequestsScreenState();
}

class _MyGalleryRequestsScreenState extends State<MyGalleryRequestsScreen> {
  String? companyId;

  @override
  void initState() {
    super.initState();
    fetchCompanyId();
  }

  Future<void> fetchCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('Organizer').doc(uid).get();
    setState(() {
      companyId = doc.data()?['company_id'];
    });
  }

  Future<List<QueryDocumentSnapshot>> fetchMyRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('gallery_requests')
        .where('requested_by', isEqualTo: uid)
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

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(
          child: Text(
            'تأكيد الحذف',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: mainFont,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا الطلب؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: mainFont,
            fontSize: 15,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center, // توسيط الأزرار
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
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: mainFont,
                color: Colors.redAccent,
              ),
            ),
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
    final status = data['status'] ?? '';
    final statusText = getStatusText(status);
    final statusColor = getStatusColor(status);

    return FutureBuilder(
      future: Future.wait([
        // Fetch classification name
        (data['classification id'] != null)
            ? (data['classification id'] as DocumentReference).get()
            : Future.value(null),
        // Fetch city name
        (data['city'] != null)
            ? FirebaseFirestore.instance
                .collection('city')
                .doc(data['city'])
                .get()
            : Future.value(null),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final classificationName = snapshot.hasData &&
                snapshot.data![0] != null &&
                snapshot.data![0].exists
            ? (snapshot.data![0].data() as Map<String, dynamic>)['name'] ??
                '---'
            : '---';

        final cityName = snapshot.hasData &&
                snapshot.data![1] != null &&
                snapshot.data![1].exists
            ? (snapshot.data![1].data() as Map<String, dynamic>)['name'] ??
                '---'
            : data['city'] ?? '---';

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تاريخ الطلب: $formattedRequestedAt',
                        style: const TextStyle(
                            fontFamily: mainFont,
                            color: Color.fromARGB(255, 133, 132, 132))),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      onPressed: () => _showDeleteConfirmation(doc.id),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'عنوان المعرض: ${data['title'] ?? 'بدون عنوان'}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('الحالة: ',
                        style: TextStyle(
                            fontFamily: mainFont, fontWeight: FontWeight.bold)),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: mainFont,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('الوصف: ${data['description'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                Text('الشركة: ${data['company_name'] ?? '---'}',
                    style: const TextStyle(fontFamily: mainFont)),
                Text('المدينة: $cityName',
                    style: const TextStyle(fontFamily: mainFont)),
                Text('التصنيف: $classificationName',
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
                  TextButton(
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String getStatusText(String? status) {
    if (status == 'accepted') return 'مقبولة';
    if (status == 'pending') return 'معلقة';
    if (status == 'rejected') return 'مرفوضة';
    return 'غير معروفة';
  }

  Color getStatusColor(String? status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'طلباتي',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 100 : 20, vertical: 20),
          child: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: fetchMyRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('لا توجد طلبات',
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
