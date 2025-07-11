import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/constants.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewGalleryDataScreen extends StatelessWidget {
  final String galleryId;

  const ViewGalleryDataScreen({Key? key, required this.galleryId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض بيانات المعرض ',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white)),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('2').doc(galleryId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('لا توجد بيانات للمعرض'));
          }

          final galleryData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // تغيير المحاذاة إلى اليمين
              children: [
                const SizedBox(height: 20), // بادينق فوق
                Text('العنوان: ${galleryData['title']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      color: const Color.fromARGB(255, 12, 12, 12),
                    )),
                const SizedBox(height: 10),
                Text('الوصف: ${galleryData['description']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      color: const Color.fromARGB(255, 12, 12, 12),
                    )),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // فتح الرابط في المتصفح
                    launch(galleryData['location']);
                  },
                  child: Text('الموقع: ${galleryData['location']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: mainFont,
                        color: const Color.fromARGB(255, 1, 82, 149),
                      )),
                ),

                const SizedBox(height: 10),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('city')
                      .doc(galleryData['city']) // استخدام معرف المدينة
                      .get(),
                  builder: (context, citySnapshot) {
                    if (citySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (citySnapshot.hasError) {
                      return Center(
                          child: Text(
                              'حدث خطأ في جلب المدينة: ${citySnapshot.error}'));
                    }
                    if (!citySnapshot.hasData || !citySnapshot.data!.exists) {
                      return const Text('لا يوجد بيانات للمدينة');
                    }

                    final cityData =
                        citySnapshot.data!.data() as Map<String, dynamic>;
                    return Text('المدينة: ${cityData['name']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: mainFont,
                          color: const Color.fromARGB(255, 12, 12, 12),
                        ));
                  },
                ),
                const SizedBox(height: 10),
                Text('تاريخ البدء: ${galleryData['start date']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      color: const Color.fromARGB(255, 12, 12, 12),
                    )),
                const SizedBox(height: 10),
                Text('تاريخ الانتهاء: ${galleryData['end date']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      color: const Color.fromARGB(255, 12, 12, 12),
                    )),
                const SizedBox(height: 10),

                // عرض اسم الشركة وعدد الأجنحة
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('company')
                      .doc(galleryData['company_id']) // استخدام معرف الشركة
                      .get(),
                  builder: (context, companySnapshot) {
                    if (companySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (companySnapshot.hasError) {
                      return Center(
                          child: Text(
                              'حدث خطأ في جلب بيانات الشركة: ${companySnapshot.error}'));
                    }
                    if (!companySnapshot.hasData ||
                        !companySnapshot.data!.exists) {
                      return const Text('لا يوجد بيانات للشركة');
                    }

                    final companyData =
                        companySnapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('اسم الشركة: ${companyData['name']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: mainFont,
                              color: const Color.fromARGB(255, 12, 12, 12),
                            )),
                        const SizedBox(height: 10),
                        Text('عدد الأجنحة: ${galleryData['suites'].length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: mainFont,
                              color: const Color.fromARGB(255, 12, 12, 12),
                            )),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 10),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('classification')
                      .doc(galleryData['classification id'].id)
                      .get(),
                  builder: (context, classificationSnapshot) {
                    if (classificationSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (classificationSnapshot.hasError) {
                      return Center(
                          child: Text(
                              'حدث خطأ في جلب التصنيف: ${classificationSnapshot.error}'));
                    }
                    if (!classificationSnapshot.hasData ||
                        !classificationSnapshot.data!.exists) {
                      return const Text('لا يوجد تصنيف لهذا المعرض');
                    }

                    final classificationData = classificationSnapshot.data!
                        .data() as Map<String, dynamic>;
                    return Text('التصنيف: ${classificationData['name']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: mainFont,
                          color: Color.fromARGB(255, 12, 12, 12),
                        ));
                  },
                ),
                const SizedBox(height: 35),
                Text(' صورة المعرض ${galleryData['QR code']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    )),
                const SizedBox(height: 10),
                Image.network(
                  galleryData['image url'],
                  height: 450, // حجم الصورة أصغر
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 35),
                Text(' صورة خارطة المعرض ',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    )),
                const SizedBox(height: 10),
                Image.network(
                  galleryData['map'],
                  height: 450, // حجم الصورة أصغر
                  fit: BoxFit.cover,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
