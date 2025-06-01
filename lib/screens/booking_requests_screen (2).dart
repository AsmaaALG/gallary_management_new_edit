import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRequestsScreen extends StatefulWidget {
  final String adId;
  const BookingRequestsScreen({Key? key, required this.adId}) : super(key: key);

  @override
  _BookingRequestsScreenState createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  String _searchQuery = '';

  Future<bool> _isAdActive(String adId) async {
    try {
      final adData = await _firestoreService.getDocumentById('ads', adId);
      if (adData == null) return false;

      final startDateStr = adData['start date'] ?? '';
      if (startDateStr.isEmpty) return false;

      final startDate = DateFormat('dd-MM-yyyy').parse(startDateStr);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      return startDate.isBefore(todayDate) ||
          startDate.isAtSameMomentAs(todayDate);
    } catch (e) {
      print('Error checking ad date: $e');
      return false;
    }
  }

  Future<bool> _isWingAlreadyBooked(String wingName, String adId) async {
    try {
      final querySnapshot = await _firestoreService.getDocumentsByQuery(
        'suite',
        whereFields: [
          {'field': 'name', 'value': wingName},
          {'field': 'gallery id', 'value': adId},
        ],
      );
      return querySnapshot.isNotEmpty;
    } catch (e) {
      print('Error checking wing status: $e');
      return false;
    }
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontFamily: mainFont,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل أنت متأكد من عملية الحذف؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: mainFont,
            color: Color.fromARGB(255, 45, 44, 44),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 15,
                fontFamily: mainFont,
                color: Color.fromARGB(255, 76, 74, 74),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.updateDocument(
                'space_form',
                docId,
                {'status': 'rejected'},
              );
              await _firestoreService.deleteBookingRequest(docId);
              Navigator.of(ctx).pop();
              setState(() {
                _requestsFuture =
                    _firestoreService.getBookingRequestsForAd(widget.adId);
              });
            },
            child: const Text(
              'حذف',
              style: TextStyle(
                fontSize: 15,
                fontFamily: mainFont,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String docId, String wingName) async {
    try {
      // 1. Get the booking request data
      final requestData =
          await _firestoreService.getDocumentById('space_form', docId);
      if (requestData == null) {
        throw Exception('طلب الحجز غير موجود');
      }

      // 2. Check if wing is already booked
      final isAlreadyBooked = await _isWingAlreadyBooked(wingName, widget.adId);
      if (isAlreadyBooked) {
        throw Exception('هذا الجناح محجوز بالفعل');
      }

      // 3. Prepare data for suite collection
      final suiteData = {
        'description': requestData['description'] ?? '',
        'name': requestData['wingName'] ?? '',
        'main image': requestData['wingImage'] ?? '',
        'gallery id': requestData['adId'] ?? '',
        'createdAt': DateTime.now(),
      };

      // 4. Add to suite collection
      await _firestoreService.addDocument('suite', suiteData);

      // 5. Update request status to 'accepted'
      await _firestoreService.updateDocument(
        'space_form',
        docId,
        {'status': 'accepted'},
      );

      // 6. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب وحجز الجناح بنجاح'),
          backgroundColor: Color.fromARGB(255, 82, 82, 82),
        ),
      );

      // 7. Refresh the list
      setState(() {
        _requestsFuture =
            _firestoreService.getBookingRequestsForAd(widget.adId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAcceptConfirmation(String docId, String wingName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الطلب',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontFamily: mainFont,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل تود تأكيد الطلب وحجز الجناح؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: mainFont,
            color: Color.fromARGB(255, 45, 44, 44),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 15,
                fontFamily: mainFont,
                color: Color.fromARGB(255, 76, 74, 74),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _acceptRequest(docId, wingName);
            },
            child: const Text(
              'تأكيد',
              style: TextStyle(
                fontSize: 15,
                fontFamily: mainFont,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _requestsFuture = _firestoreService.getBookingRequestsForAd(widget.adId);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirectionRTL,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: primaryColor,
          title: const Text(
            'طلبات حجز الأجنحة',
            style: TextStyle(
              color: Colors.white,
              fontFamily: mainFont,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(19.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إدارة طلبات الحجز',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: mainFont,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 15),
              const Text(
                'من خلال هذه اللوحة يمكنك تتبع جميع طلبات الحجز للمعرض المحدد',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: mainFont,
                  color: Color.fromARGB(255, 46, 46, 46),
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 3),
                child: SizedBox(
                  height: 60,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالبريد أو المؤسسة',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontFamily: mainFont,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                          size: 18,
                        ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: mainFont,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(
                          child: Text('حدث خطأ أثناء تحميل الطلبات'));
                    } else if (snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد طلبات حجز لهذا المعرض',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: mainFont,
                            color: Color.fromARGB(255, 117, 116, 116),
                          ),
                        ),
                      );
                    } else {
                      final filteredRequests = snapshot.data!.where((data) {
                        final email = (data['email'] ?? '').toLowerCase();
                        final org = (data['organization'] ?? '').toLowerCase();
                        return email.contains(_searchQuery) ||
                            org.contains(_searchQuery);
                      }).toList();

                      if (filteredRequests.isEmpty) {
                        return const Center(
                            child: Text('لا توجد نتائج مطابقة'));
                      }

                      return ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          var data = filteredRequests[index];
                          String docId = data['docId'] ?? '';
                          String wingName = data['wingName'] ?? '';
                          bool isAccepted = data['status'] == 'accepted';

                          return FutureBuilder<bool>(
                            future: Future.wait([
                              _isAdActive(widget.adId),
                              _isWingAlreadyBooked(wingName, widget.adId),
                            ]).then((results) => results[0] && !results[1]),
                            builder: (context, combinedSnapshot) {
                              final isActiveAndNotBooked =
                                  combinedSnapshot.data ?? false;
                              final isBooked = combinedSnapshot.hasData
                                  ? !combinedSnapshot.data!
                                  : false;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: primaryColor),
                                            onPressed: () =>
                                                _showDeleteConfirmation(docId),
                                          ),
                                        ],
                                      ),
                                      Text(
                                          'الاسم: ${data['name'] ?? 'غير معروف'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      Text('البريد: ${data['email'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      Text('الهاتف: ${data['phone'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      const Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                          'اسم الجناح: ${data['wingName'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      Text(
                                          'المنظمة: ${data['organization'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      Text(
                                          'الوصف: ${data['description'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      Text(
                                          'صورة الجناح: ${data['wingImage'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 10),
                                      Text(
                                          'العنوان: ${data['address'] ?? '---'}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: mainFont)),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          if (isAccepted || isBooked)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                ' قبول الطلب',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: mainFont,
                                                  color: Color.fromARGB(
                                                      255, 53, 53, 53),
                                                ),
                                              ),
                                            )
                                          else
                                            ElevatedButton(
                                              onPressed: isActiveAndNotBooked
                                                  ? () {
                                                      _showAcceptConfirmation(
                                                          docId, wingName);
                                                    }
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    isActiveAndNotBooked
                                                        ? secondaryColor
                                                        : Colors.grey[400],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: const Text(
                                                'قبول الطلب',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: mainFont,
                                                  color: Color.fromARGB(
                                                      255, 53, 53, 53),
                                                ),
                                              ),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
