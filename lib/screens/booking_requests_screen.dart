import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

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

  @override
  void initState() {
    super.initState();
    _requestsFuture = _firestoreService.getBookingRequestsForAd(widget.adId);
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(
            fontSize: 18,
            fontFamily: mainFont,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف هذا الطلب؟',
          style: TextStyle(
            fontSize: 18,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: primaryColor,
        title: const Text(
          'طلبات الحجز',
          style: TextStyle(
            fontSize: 16,
            fontFamily: mainFont,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(19.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
              'من خلال هذه اللوحة يمكنكتتبع جميع طلبات الحجز للمعرض المحدد      ',
              style: TextStyle(
                fontSize: 15,
                fontFamily: mainFont,
                color: Color.fromARGB(255, 46, 46, 46),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),

            // مربع البحث
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 3),
              child: Directionality(
                textDirection: TextDirection.rtl,
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
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
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
            ),
            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _requestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text('حدث خطأ أثناء تحميل الطلبات'));
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد طلبات حجز'));
                  } else {
                    // فلترة الطلبات حسب البريد أو المؤسسة
                    final filteredRequests = snapshot.data!.where((data) {
                      final email = (data['email'] ?? '').toLowerCase();
                      final org = (data['organization'] ?? '').toLowerCase();
                      return email.contains(_searchQuery) ||
                          org.contains(_searchQuery);
                    }).toList();

                    if (filteredRequests.isEmpty) {
                      return const Center(child: Text('لا توجد نتائج مطابقة'));
                    }

                    return ListView.builder(
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        var data = filteredRequests[index];
                        String docId = data['docId'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: primaryColor),
                                      onPressed: () =>
                                          _showDeleteConfirmation(docId),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                Text(
                                  'الاسم: ${data['name'] ?? 'غير معروف'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: mainFont,
                                    color: Color.fromARGB(255, 53, 53, 53),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'البريد: ${data['email'] ?? '---'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: mainFont,
                                    color: Color.fromARGB(255, 53, 53, 53),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'الهاتف: ${data['phone'] ?? '---'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: mainFont,
                                    color: Color.fromARGB(255, 53, 53, 53),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'المنظمة: ${data['organization'] ?? '---'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: mainFont,
                                    color: Color.fromARGB(255, 53, 53, 53),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'المنتج: ${data['productType'] ?? '---'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: mainFont,
                                    color: Color.fromARGB(255, 53, 53, 53),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'العنوان: ${data['address'] ?? '---'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: mainFont,
                                    color: Color.fromARGB(255, 53, 53, 53),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    // تنفيذ عند الضغط على "قبول الطلب"
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor,
                                  ),
                                  child: const Text(
                                    'قبول الطلب',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: mainFont,
                                      color: Color.fromARGB(255, 53, 53, 53),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
