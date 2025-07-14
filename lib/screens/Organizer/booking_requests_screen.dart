// الكود الكامل لواجهة BookingRequestsScreen مع حذف الطلب المقبول وعدم تخزينه في جدول منفصل
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/screens/Organizer/accepted_booking_requests_screen.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingRequestsScreen extends StatefulWidget {
  final String adId;
  final String adname;

  const BookingRequestsScreen(
      {Key? key, required this.adId, required this.adname})
      : super(key: key);

  @override
  _BookingRequestsScreenState createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _requestsFuture = _firestoreService.getBookingRequestsForAd(widget.adId);
  }

  Future<void> _handleAccept(String docId, Map<String, dynamic> data) async {
    try {
      final suiteName = data['selectedSuite']['name'];

      //  تحقق هل تم إنشاء المعرض من قبل
      final galleryId = await _firestoreService.getGalleryIdByAdId(widget.adId);

      if (galleryId != null) {
        //  تم إنشاء المعرض، قم بإنشاء الجناح
        await FirebaseFirestore.instance.collection('suite').add({
          'name': data['wingName'] ?? 'جناح بدون اسم',
          'description': data['description'] ?? '',
          'price': int.tryParse(data['selectedSuite']['price'] ?? '0') ?? 0,
          'size': int.tryParse(data['selectedSuite']['area'] ?? '0') ?? 0,
          'title on map': suiteName,
          'gallery id': galleryId,
        });
      } else {
        print(' لم يتم فتح المعرض بعد، لن يتم إنشاء الجناح الآن');
      }

      await _firestoreService.updateSuiteStatusInAd(widget.adId, suiteName);
      await _firestoreService.disableOtherRequestsForSameSuite(
        widget.adId,
        suiteName,
        docId,
      );
      await _firestoreService.markRequestAsAccepted(docId);

      setState(() {
        _requestsFuture =
            _firestoreService.getBookingRequestsForAd(widget.adId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            galleryId != null
                ? 'تم قبول الطلب وإنشاء الجناح'
                : 'تم قبول الطلب، وسيتم إنشاء الجناح عند فتح المعرض',
          ),
          backgroundColor: Colors.grey,
        ),
      );
      if (galleryId != null) {
        await FirebaseFirestore.instance
            .collection('space_form')
            .doc(docId)
            .delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAcceptDialog(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد القبول'),
          content: const Text('هل ترغب في تأكيد الطلب وإضافة الجناح؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _handleAccept(docId, data);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: textDirectionRTL,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.checklist_rounded, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AcceptedBookingRequestsScreen(
                      adId: widget.adId,
                    ),
                  ),
                );

                setState(() {
                  _requestsFuture =
                      _firestoreService.getBookingRequestsForAd(widget.adId);
                });
              },
            ),
          ],
          backgroundColor: primaryColor,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: 20, horizontal: isWideScreen ? 80 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إدارة طلبات الحجز',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: mainFont,
                      color: primaryColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text(
                  'من خلال هذه اللوحة يمكنك تتبع جميع طلبات الحجز للمعرض المحدد',
                  style: TextStyle(
                      fontSize: 15,
                      fontFamily: mainFont,
                      color: Color.fromARGB(255, 46, 46, 46))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: SizedBox(
                  width: isWideScreen ? 500 : double.infinity,
                  height: 60,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالبريد أو المؤسسة',
                      hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontFamily: mainFont),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.search,
                            color: Colors.grey[500], size: 18),
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 228, 226, 226),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12, fontFamily: mainFont),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || snapshot.data == null) {
                      return const Center(
                          child: Text('حدث خطأ أثناء تحميل الطلبات'));
                    }

                    final filtered = snapshot.data!
                        .where((data) => data['accepted'] != true)
                        .where((data) {
                      final email = (data['email'] ?? '').toLowerCase();
                      final org = (data['organization'] ?? '').toLowerCase();
                      return email.contains(_searchQuery) ||
                          org.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                          child: Text('لا توجد طلبات حجز متاحة'));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index];
                        final docId = data['docId'];
                        final isDisabled = data['disabled'] == true;

                        return booking_requests_card(docId, data, isDisabled);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card booking_requests_card(
      docId, Map<String, dynamic> data, bool isDisabled) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: primaryColor),
                  onPressed: () => _showDeleteConfirmation(docId),
                ),
              ],
            ),
            Text('الاسم: ${data['name'] ?? 'غير معروف'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            Text('البريد: ${data['email'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            Text('الهاتف: ${data['phone'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            const SizedBox(height: 10),
            Text('اسم الجناح: ${data['wingName'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            Text('المنظمة: ${data['organization'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            Text('الجناح: ${data['selectedSuite'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            Text('نوع العارض: ${data['organizationType'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            Text('الوصف: ${data['description'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Text('العنوان: ${data['address'] ?? '---'}',
                style: const TextStyle(fontSize: 14, fontFamily: mainFont)),
            const SizedBox(height: 20),
            const Divider(),
            ElevatedButton.icon(
              onPressed: isDisabled
                  ? () async {
                      final emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: data['email'],
                        query: Uri.encodeFull(
                            'subject=رفض طلب حجز جناح&body=تعلمك إدارة ${widget.adname} بأن الجناح الذي طلبته تم حجزه من قبل طلب أخر يمكنك إعادة إرسال الطلب واختيار جناح أخر'),
                      );
                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      }
                    }
                  : () async {
                      final emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: data['email'],
                        query: Uri.encodeFull(
                            'subject=قبول طلب حجز جناح&body= تم قبول طلبك لحجز جناح في ${widget.adname} يرجى التواصل معنا لاستكمال اجراءات الحجز والدفع'),
                      );
                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              icon:
                  const Icon(Icons.mail_outline, size: 18, color: Colors.white),
              label: Text(
                  isDisabled
                      ? 'إرسال برد للإعلام باختيار جناح جديد'
                      : 'إرسال بريد قبول الطلب',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  isDisabled ? null : () => _showAcceptDialog(docId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey[400] : secondaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                isDisabled
                    ? 'الجناح المطلوب محجوز مسبقًا'
                    : 'إضافة الجناح للمعرض',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                await _firestoreService.deleteBookingRequest(docId);
                Navigator.pop(ctx);
                setState(() {
                  _requestsFuture =
                      _firestoreService.getBookingRequestsForAd(widget.adId);
                });
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}
