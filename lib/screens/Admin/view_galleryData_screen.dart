import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/dynamic_view_card.dart';

class ViewGalleryDataScreen extends StatelessWidget {
  final String galleryId;

  const ViewGalleryDataScreen({Key? key, required this.galleryId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'عرض بيانات المعرض',
          style: TextStyle(
            fontSize: 16,
            fontFamily: mainFont,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('2').doc(galleryId).get(),
        builder: (context, gallerySnapshot) {
          if (gallerySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gallerySnapshot.hasError ||
              !gallerySnapshot.hasData ||
              !gallerySnapshot.data!.exists) {
            return const Center(child: Text('تعذر تحميل بيانات المعرض'));
          }

          final galleryData =
              gallerySnapshot.data!.data() as Map<String, dynamic>;
          final companyId = galleryData['company_id'];

          // استعلام لحساب عدد الأجنحة المرتبطة بالمعرض
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('suite')
                .where('gallery id', isEqualTo: galleryId)
                .get(),
            builder: (context, suitesSnapshot) {
              if (suitesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final suitesCount = suitesSnapshot.data?.docs.length ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: companyId != null
                    ? FirebaseFirestore.instance
                        .collection('company')
                        .doc(companyId)
                        .get()
                    : Future.value(null),
                builder: (context, companySnapshot) {
                  String companyName = 'غير متاح';

                  if (companySnapshot.hasData &&
                      companySnapshot.data != null &&
                      companySnapshot.data!.exists) {
                    final companyData =
                        companySnapshot.data!.data() as Map<String, dynamic>;
                    companyName = companyData['name']?.toString() ?? 'غير متاح';
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DynamicViewCard(
                          title: galleryData['title']?.toString() ?? 'غير متاح',
                          description: galleryData['description']?.toString() ??
                              'غير متاح',
                          location:
                              galleryData['location']?.toString() ?? 'غير متاح',
                          startDate: galleryData['start date']?.toString() ??
                              'غير متاح',
                          endDate:
                              galleryData['end date']?.toString() ?? 'غير متاح',
                          cityId: galleryData['city'] ?? '',
                          classificationRef: galleryData['classification id'],
                          qrCode:
                              galleryData['QR code']?.toString() ?? 'غير متاح',
                          suitesCount: suitesCount,
                          imageUrl: galleryData['image url'] ?? '',
                          mapUrl: galleryData['map'] ?? '',
                          stopAd: '',
                          companyName: companyName,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
