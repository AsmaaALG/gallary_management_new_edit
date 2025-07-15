import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/dynamic_view_card.dart';

class ViewAdsDataScreen extends StatelessWidget {
  final String galleryId;

  const ViewAdsDataScreen({Key? key, required this.galleryId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض بيانات الإعلان',
            style: TextStyle(
                fontSize: 16, fontFamily: mainFont, color: Colors.white)),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('ads').doc(galleryId).get(),
        builder: (context, gallerySnapshot) {
          if (gallerySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (gallerySnapshot.hasError ||
              !gallerySnapshot.hasData ||
              !gallerySnapshot.data!.exists) {
            return const Center(child: Text('تعذر تحميل بيانات الإعلان'));
          }

          final galleryData =
              gallerySnapshot.data!.data() as Map<String, dynamic>;
          final suitesCount = galleryData['suites']?.length ?? 0;
          final companyId = galleryData['company_id'];

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
                      description:
                          galleryData['description']?.toString() ?? 'غير متاح',
                      location:
                          galleryData['location']?.toString() ?? 'غير متاح',
                      startDate:
                          galleryData['start date']?.toString() ?? 'غير متاح',
                      endDate:
                          galleryData['end date']?.toString() ?? 'غير متاح',
                      stopAd: galleryData['stopAd']?.toString() ?? 'غير متاح',
                      cityId: galleryData['city'] ?? '',
                      classificationRef: galleryData['classification id'],
                      qrCode: galleryData['QR code']?.toString() ?? 'غير متاح',
                      suitesCount: suitesCount,
                      imageUrl: galleryData['image url'] ?? '',
                      mapUrl: galleryData['map'] ?? '',
                      companyName: companyName, 
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
