// واجهة الطلبات المقبولة (AcceptedBookingRequestsScreen)
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

class AcceptedBookingRequestsScreen extends StatefulWidget {
  final String adId;
  const AcceptedBookingRequestsScreen({super.key, required this.adId});

  @override
  State<AcceptedBookingRequestsScreen> createState() =>
      _AcceptedBookingRequestsScreenState();
}

class _AcceptedBookingRequestsScreenState
    extends State<AcceptedBookingRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _acceptedRequestsFuture;

  @override
  void initState() {
    super.initState();
    _loadAcceptedRequests();
  }

  void _loadAcceptedRequests() {
    _acceptedRequestsFuture =
        _firestoreService.getAcceptedBookingRequests(widget.adId);
  }

  Future<void> _cancelAcceptance(String docId, String suiteName) async {
    try {
      // 1. تحديث الجناح ليصبح متاح
      await _firestoreService.updateSuiteStatusInAd(widget.adId, suiteName,
          available: true);

      // 2. إعادة تفعيل الطلبات الأخرى التي تطلب نفس الجناح
      await _firestoreService.enableOtherRequestsForSameSuite(
          widget.adId, suiteName);

      // 3. إزالة حالة القبول من الطلب الحالي
      await _firestoreService.unmarkRequestAsAccepted(docId);

      setState(() {
        _loadAcceptedRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم إلغاء حجز الجناح بنجاح"),
            backgroundColor: Colors.grey),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: \$e"), backgroundColor: Colors.grey),
      );
    }
  }

  void _showCancelDialog(String docId, String suiteName) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد إلغاء الحجز"),
          content: const Text("هل أنت متأكد من التراجع عن قبول هذا الطلب؟"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إلغاء")),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _cancelAcceptance(docId, suiteName);
              },
              child: const Text("تأكيد"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirectionRTL,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text(
            "الطلبات المقبولة",
            style: TextStyle(
                color: Colors.white, fontFamily: mainFont, fontSize: 16),
          ),
          backgroundColor: primaryColor,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _acceptedRequestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text("لا توجد طلبات مقبولة"));
            }

            final requests = snapshot.data!;

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final data = requests[index];
                final docId = data['docId'];
                final suiteName = data['selectedSuite']['name'] ?? '---';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الاسم: ${data['name'] ?? 'غير معروف'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        Text('البريد: ${data['email'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        Text('الهاتف: ${data['phone'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        const SizedBox(height: 10),
                        Text('اسم الجناح: ${data['wingName'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        Text('المنظمة: ${data['organization'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        Text('الجناح: ${data['selectedSuite'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        Text('نوع العارض: ${data['organizationType'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        Text('الوصف: ${data['description'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Text('العنوان: ${data['address'] ?? '---'}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: mainFont)),
                        const SizedBox(height: 20),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _showCancelDialog(docId, suiteName),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[300],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("إلغاء الحجز",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
