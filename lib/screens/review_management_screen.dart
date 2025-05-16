import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

class ReviewManagementScreen extends StatefulWidget {
  final String galleryId;
  const ReviewManagementScreen({
    super.key,
    required this.galleryId,
  });

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 251, 251),
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'ادارة التعليقات',
                style: TextStyle(
                  fontFamily: mainFont,
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            children: [
              const Text(
                'من خلال هذه الواجهة يمكنك متابعة أحدث التعليقات وإضافة مقالات وتعليقات جديدة',
                style: TextStyle(fontFamily: mainFont, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // مربع البحث العادي
              Container(
                width: MediaQuery.of(context).size.width *
                    0.75, // عرض نسبي أقل من كامل الشاشة
                height: 50,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 228, 226, 226),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: mainFont,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المستخدم أو التعليق',
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
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('gallery id', isEqualTo: widget.galleryId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reviews = snapshot.data!.docs;
                    final filtered = reviews.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final comment =
                          data['comment']?.toString().toLowerCase() ?? '';
                      return comment
                          .contains(_searchController.text.toLowerCase());
                    }).toList();

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data =
                            filtered[index].data() as Map<String, dynamic>;
                        final reviewId = filtered[index].id;
                        final comment = data['comment'] ?? '';
                        final stars =
                            data['number of stars']?.toString() ?? '0';
                        final userId = data['user id'];

                        return FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .where('userId', isEqualTo: userId)
                              .limit(1)
                              .get(),
                          builder: (context, userSnapshot) {
                            final userData = userSnapshot.data != null &&
                                    userSnapshot.data!.docs.isNotEmpty
                                ? userSnapshot.data!.docs.first.data()
                                    as Map<String, dynamic>
                                : null;

                            final username = userData != null
                                ? "${userData['first_name']} ${userData['last_name']}"
                                : "مستخدم غير معروف";

                            // ... تابع باقي تصميم واجهة التعليق

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(131, 241, 185, 185),
                                  width: 2,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(35),
                                  topRight: Radius.circular(0),
                                  bottomLeft: Radius.circular(35),
                                  bottomRight: Radius.circular(35),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                child: Row(
                                  children: [
                                    // زر الحذف
                                    GestureDetector(
                                      onTap: () async {
                                        final confirmed = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            title: const Text(
                                              'تأكيد الحذف',
                                              style: TextStyle(
                                                  color: primaryColor,
                                                  fontFamily: mainFont),
                                              textAlign: TextAlign.center,
                                            ),
                                            content: const Text(
                                                'هل أنت متأكد من حذف هذا التعليق؟',
                                                style: TextStyle(
                                                    fontFamily: mainFont)),
                                            actions: [
                                              TextButton(
                                                child: const Text('إلغاء',
                                                    style: TextStyle(
                                                        fontFamily: mainFont)),
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                              ),
                                              TextButton(
                                                child: const Text('حذف',
                                                    style: TextStyle(
                                                      fontFamily: mainFont,
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    )),
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          await FirebaseFirestore.instance
                                              .collection('reviews')
                                              .doc(reviewId)
                                              .delete();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              Color.fromARGB(255, 254, 214, 90),
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 18,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255)),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // محتوى التعليق
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                username,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: mainFont,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                  Icons.star_rate_rounded,
                                                  size: 15,
                                                  color: secondaryColor),
                                              const SizedBox(width: 2),
                                              Text(
                                                stars,
                                                style: const TextStyle(
                                                  fontFamily: mainFont,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5),
                                            child: Text(
                                              comment,
                                              style: const TextStyle(
                                                  fontFamily: mainFont,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
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
}
